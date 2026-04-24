# Follow-up Questions

Based on your answers in QUESTIONS.md. Check one option per question.

---

## F1. Config struct shape (#5)

You want per-context config, loaded in `cmd/`, injected into `init.go`. Where does the config struct live?

- [ ] **A)** `internal/{context}/config.go` — a `Config` struct in the context package itself, next to `init.go`. `Setup(ctx, cfg Config)` instead of `Setup(ctx, databaseURL)`.
- [*] **B)** `internal/{context}/config/config.go` — separate package. `config.Load()` returns `*config.Config`. `cmd/` calls `config.Load()` then passes to `init.go`.
- [ ] **C)** Config struct lives in `cmd/{context}/config.go` — it's a composition root concern. `init.go` receives individual deps (pool, logger, etc.), not a config object.

---

## F2. Validator tags location (#7)

You want `playground/validator`. Where do the `validate:"..."` tags go?

- [*] **A)** On the public request types in `pkg/{context}/` (e.g. `Name string \`json:"name" validate:"required,min=1,max=255"\``). Handlers call `validator.Struct(req)` before converting to domain.
- [ ] **B)** On separate validation structs in `inbound/http/shared/` that mirror the request types. Keeps `pkg/` clean of validation framework deps.
- [ ] **C)** On the `pkg/` request types, but add a `Validate()` method that wraps the validator call so handlers just call `req.Validate()`.

---

## F3. Cursor pagination domain type (#8)

You prefer cursor-based. What shape for the domain types?

- [*] **A)** Generic `ListParams` and `ListResult`:
  ```go
  // domain/query.go
  type ListParams struct {
      Cursor string // opaque cursor, empty = first page
      Limit  int
  }
  type ListResult[T any] struct {
      Items      []T
      NextCursor string // empty = no more pages
  }
  ```
- [ ] **B)** Same but without generics — each entity gets its own result type:
  ```go
  type ListParams struct { Cursor string; Limit int }
  // per entity in service interface:
  List(ctx, actor, params ListParams) ([]*Entity, string, error) // items, nextCursor, err
  ```
- [ ] **C)** Embed cursor in per-entity filter structs:
  ```go
  type List{Entity}Params struct {
      Cursor string
      Limit  int
      // entity-specific filters added here
  }
  ```

---

## F4. Port interfaces: usecases + commands/queries split (#10 + #11)

You want:
- `domain/usecases/` for port interfaces (implemented by `app/`)
- `domain/services/` for pure domain logic
- One command interface + one query interface per entity

Confirming the structure:

- [ ] **A)** Split interfaces in the usecases package:
  ```
  domain/usecases/{entity}/
      commands.go  — {Entity}Commands interface (Create, Update, Delete)
      queries.go   — {Entity}Queries interface (GetByID, List)
  ```
  `app/` implements both. Inbound `commands/` depends on `{Entity}Commands`, inbound `queries/` depends on `{Entity}Queries`.

- [*] **B)** Single file, two interfaces:
  ```
  domain/usecases/{entity}/{entity}.go
      type {Entity}Commands interface { ... }
      type {Entity}Queries interface { ... }
  ```

- [ ] **C)** Single file, single combined interface (keep current pattern, just rename the package):
  ```
  domain/usecases/{entity}/{entity}.go
      type {Entity}Service interface { ... } // both reads and writes
  ```

---

## F5. domain/services/ pure domain logic shape (#10)

For pure domain services (business logic, no I/O), what should the template scaffold?

- [ ] **A)** One service per entity: `domain/services/{entity}.go` — struct with methods, receives domain types only, no interfaces/ports.
- [*] **B)** Grouped by concern: `domain/services/{concern}.go` (e.g. `pricing.go`, `eligibility.go`) — not tied to a single entity.
- [ ] **C)** Just a `domain/services/` directory created at bootstrap, empty. No per-entity template — pure domain services are too varied to scaffold.

with domain/usecases is domain/services needed ?

---

## F6. Mocks and contracts for usecases (#10 + #11)

Currently mocks and contracts exist for both repositories and services. With the rename to `usecases/` and the commands/queries split, should we keep mock+contract per interface?

- [*] **A)** Yes, mirror the repository pattern: `domain/usecases/{entity}/{entity}test/mock.go` + `contract.go` for both Commands and Queries interfaces.
- [ ] **B)** Mock only (via go-surgeon), skip contract tests for usecases. Contract tests are more valuable for repos (real DB).
- [ ] **C)** No change — keep the same mock+contract pattern but adapted for the two interfaces.

---

## F7. add_cmd command shape (#15)

You want `add_cmd` for additional binaries (worker, migrator, etc.). What variables?

- [*] **A)** `add_cmd --set Context=server --set Binary=worker --set ModulePath=...` → creates `cmd/{Binary}/main.go` that imports `internal/{Context}/`.
- [ ] **B)** `add_cmd --set Binary=worker --set ModulePath=...` → creates `cmd/{Binary}/main.go` as a standalone entry point (no context import, user wires it).
- [ ] **C)** `add_cmd --set Context=server --set Binary=worker --set BinaryType=worker --set ModulePath=...` where `BinaryType` selects a template variant (api, worker, migrator each have different boilerplate).

---

## F8. Middleware chain wiring (#3)

You picked C — middleware in `inbound/http/shared/middleware.go`. How should it be wired?

- [ ] **A)** `inbound/http/init.go` wraps the mux: `SetupRouter` returns `http.Handler` (mux wrapped in middleware chain). `init.go` at context level uses the wrapped handler.
- [ ] **B)** Middleware applied in `cmd/{context}/main.go` around the handler returned by `Setup()`.
- [*] **C)** `inbound/http/init.go` takes a middleware chain as parameter: `SetupRouter(mux, a, middlewares ...func(http.Handler) http.Handler)`.

---

## F9. OTel + slog init location (#4)

You picked C — full observability. Where does the OTel provider + slog init live?

- [*] **A)** `cmd/{context}/main.go` — init OTel provider, create slog handler, pass logger to `Setup()`. Shutdown provider in defer.
- [ ] **B)** `internal/{context}/observability/` package — `Setup()` returns `(*slog.Logger, func())` (logger + shutdown). Called from `cmd/main.go`.
- [ ] **C)** Split: OTel provider in `cmd/main.go` (infra concern), slog handler creation in `internal/{context}/init.go` (receives otel provider as dep).

---

## F10. Publisher port naming (#2)

You want full publisher/consumer scaffolding. For the publisher port interface in domain:

- [*] **A)** `domain/publishers/{entity}/{entity}.go` — mirrors `domain/repositories/{entity}/`
- [ ] **B)** `domain/ports/outbound/{entity}_publisher.go` — if you later want all outbound ports together
- [ ] **C)** `domain/events/{entity}/publisher.go` — grouped by event concern rather than port direction
