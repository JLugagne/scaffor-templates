# Review Round 3 — Questions

## Q1: Consumer architecture overhaul (covers blindspots 2, 3, 4)

These three issues are deeply intertwined — answering them together:

**The problems:**
- Consumer handler imports `*app.App` but `inbound mayDependOn: [domain, pkg]` — **arch-lint will fail**
- Consumer domain port uses `[]byte` payload — **abstraction leak** (publisher uses typed `*domain.Entity`, consumer uses raw bytes)
- `domain/consumers/` is asymmetric with other inbound ports — HTTP/gRPC handlers don't have domain interfaces, they call usecase interfaces directly

**Proposed fix (single coherent change):**

1. **Delete `domain/consumers/` entirely** — no domain port for consumers. HTTP handlers don't have one, gRPC handlers don't have one, consumers shouldn't either.
2. **Consumer handler receives usecase interfaces**, not `*app.App`:
   ```go
   type {{ .Entity | lower }}Consumer struct {
       commands {{ .Entity | lower }}.{{ .Entity }}Commands
   }
   func New{{ .Entity }}Consumer(cmds {{ .Entity | lower }}.{{ .Entity }}Commands) *{{ .Entity | lower }}Consumer { ... }
   ```
3. **Consumer deserializes `[]byte` → typed event struct** from `pkg/{Context}/events/`, then calls usecase commands — deserialization is the adapter's job, not the domain's.
4. **Arch-lint stays clean**: consumer imports `domain` (for usecase interfaces) and `pkg` (for event types) — both already allowed.

This gives perfect symmetry: all inbound adapters (HTTP, gRPC, consumers) depend on usecase interfaces from domain, never on `*app.App`.

- [x] Yes, delete `domain/consumers/`, consumer depends on usecase interfaces + pkg events
- [ ] No, keep `domain/consumers/` but fix the `[]byte` → typed events and add `app` to inbound deps
- [ ] Other: ___

## Q2: `protocol/` directory naming (blindspot 1)

The consumer template lives at `internal/context/inbound/protocol/consumers/entity.go.tmpl` but the destination uses `{{ .Protocol }}`. The literal `protocol/` directory name is confusing when browsing the template source.

**Options:**
- [x] Rename to `internal/context/inbound/_protocol/consumers/` — underscore signals "this is a placeholder"
- [ ] Rename to `internal/context/inbound/messaging/consumers/` — more descriptive but misleading (could be kafka, sqs, nats, grpc streams...)
- [ ] Keep as-is — scaffor doesn't care about source paths, just destination
- [ ] Other: ___

## Q3: Config stdlib-only constraint (blindspot 5)

`config: mayDependOn: []` in arch-lint. Currently config.go only uses `os` and `fmt` (stdlib), which is correct. But nothing prevents someone from importing a domain type later.

**Options:**
- [x] Add a comment in config.go.tmpl: `// config must only import stdlib and external deps (envconfig, etc.) — never internal packages`
- [ ] Add `domain` to config's mayDependOn as a safety valve
- [ ] Both comment + allow domain
- [ ] Other: ___

## Q4: Outbox scaffolding (blindspot 6)

Currently the outbox pattern is documented in publisher interface hints. An `add_outbox` composite command could scaffold:
- Migration: `outbox_events` table
- Outbound adapter: `outbound/{Adapter}/outbox.go` (writes to outbox table in same tx)
- Relay worker: `cmd/outbox-relay/main.go` (polls + publishes)

This is a differentiator for "production-ready batteries-included" but adds complexity.

- [x] Yes, add `add_outbox` composite command
- [ ] No, keep it documentation-only — outbox is too implementation-specific to template well
- [ ] Defer to a future iteration
- [ ] Other: ___

## Q5: DTO validation (blindspot 7)

This was already addressed in R2: `pkg/{Context}/entity.go.tmpl` has `Validate() error` using `go-playground/validator/v10` with `validate:"..."` tag hints. Confirming this is resolved.

- [x] Already addressed, no action needed
- [ ] Needs further work: ___
