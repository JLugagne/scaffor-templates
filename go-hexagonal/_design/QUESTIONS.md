# Review Round 2 — Decisions Needed

Items 2, 3, 6, 9, 10, and cleanup are clear — I'll fix them directly.
These 5 need your call:

---

## R1. Config import rules (#1)

Currently: only `composition` (init.go) can import `config`. App and outbound cannot.
This means config values (DB pool size, timeouts, feature flags) must be passed as primitive params from init.go to app/outbound constructors.

- [*] **A)** Keep composition-root-only. All config values are unpacked in init.go and passed as constructor args. Purest separation — document this explicitly in README.
- [ ] **B)** Let `app` import `config` too. The app service sometimes needs runtime config (feature flags, rate limits). Add `config` to app's `mayDependOn`.
- [ ] **C)** Let both `app` and `outbound` import `config`. Outbound adapters need connection strings, pool sizes, timeouts. Add `config` to both.

init.go must create all the outbound itself

---

## R2. Consumer mock/contract symmetry (#4)

Every other port (repository, usecase, publisher) has interface + mock + contract. Consumer only has a bare handler struct. The reviewer argues consumers are critical for deserialization/retry bugs.

- [*] **A)** Add symmetry: `add_consumer_interface` (domain port) + `add_consumer_mock` + `add_consumer_handler`. Consumer becomes a proper inbound port like HTTP/gRPC.
- [ ] **B)** Keep consumer as a simple handler. It calls usecases directly (which are already mocked/tested). Consumer-specific tests (deserialization) are written ad-hoc. Document this rationale.
- [ ] **C)** Add a consumer contract test but no domain port interface. The consumer is an inbound adapter, not a port — it's tested via e2e, similar to HTTP handlers.

---

## R3. Outbox pattern now that publishers exist (#5)

You previously said skip (#9:C). But now `app.Create()` will call `repo.Create()` then `publisher.Publish()` — the classic dual-write. If DB commits but broker fails, event is lost.

- [ ] **A)** Add `add_outbox` command now: outbox migration, `outbound/{adapter}/outbox.go`, relay consumer. Full pattern.
- [*] **B)** Keep skip. Document the dual-write risk in the publisher hint. Teams add outbox when they need exactly-once semantics.
- [ ] **C)** Integrate outbox into UoW: when `add_domain_uow` is used alongside publishers, the UoW writes events to the outbox table atomically. Add a hint explaining this combo.

---

## R4. health.go pgxpool coupling (#7)

`HandleReadyz` in `inbound/http/shared/` directly imports `pgxpool`. This couples inbound to a specific outbound driver. `go-arch-lint` doesn't catch it because `depOnAnyVendor: true`.

- [ ] **A)** Keep pragmatic. Health checks are infrastructure glue, not business logic. The coupling is acceptable and `depOnAnyVendor` is intentional. Document it.
- [*] **B)** Add a `Pinger` interface in `domain/` or `shared/`. `HandleReadyz` takes `Pinger`, pgxpool adapter implements it. Pure but more boilerplate.
- [ ] **C)** Move health handlers to the composition root (init.go registers them directly with the pool). Keeps shared/ clean.

---

## R5. cmd/ in arch-lint (#8)

`cmd/` is outside `workdir: internal` so it's completely unchecked. Any binary can import anything.

- [ ] **A)** Document in README that cmd/ is intentionally unchecked (composition root by definition).
- [ ] **B)** Add a comment in `.go-arch-lint.yml` explaining the exclusion.
- [ ] **C)** Both A and B.

cmd/ can only import /internal/<context> and /internal/<context>/config
