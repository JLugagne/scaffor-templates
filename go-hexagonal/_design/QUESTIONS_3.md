# Follow-up Questions — Round 3

---

## G1. Do we need domain/services/ at all? (#F5)

You asked: "with domain/usecases is domain/services needed?"

Here's how the layers now map:

| Package | Purpose | Example |
|---------|---------|---------|
| `domain/` | Entities, value objects, errors, typed IDs | `Actor`, `Project`, `NewProject()` |
| `domain/usecases/{entity}/` | Port interfaces (Commands + Queries), implemented by `app/` | `ProjectCommands`, `ProjectQueries` |
| `domain/repositories/{entity}/` | Outbound port interfaces, implemented by `outbound/` | `ProjectRepository` |
| `domain/publishers/{entity}/` | Outbound port interfaces for events | `ProjectPublisher` |
| `app/` | Orchestration — implements usecases, coordinates repos + publishers | `App.Create()`, `App.List()` |
| `domain/services/` | **Pure domain logic** — no I/O, no ports | `?` |

The question: is there logic that doesn't fit in entity methods (setters/constructors) and doesn't fit in `app/` (which does I/O coordination)?

Examples where `domain/services/` would be useful:
- Cross-entity business rules: "Can this actor transfer ownership?" (checks actor + project + org rules)
- Complex calculations: pricing, scoring, eligibility that touch multiple entity types
- Domain policies: "Is this state transition valid?" when the logic is too complex for a single setter

- [*] **A)** Yes, keep `domain/services/` — scaffold empty at bootstrap, add `add_domain_service` command for when teams need pure domain logic.
- [ ] **B)** No, drop it. Entity methods + `app/` orchestration cover everything. If complex domain logic emerges, teams add it ad-hoc in `domain/`.
- [ ] **C)** Rename to `domain/rules/` or `domain/policies/` to make the distinction from usecases even clearer. Scaffold empty at bootstrap.

---

## G2. Validator — shared instance or per-call? (#F2)

You want `playground/validator` with tags on `pkg/` types. How should the validator instance be managed?

- [ ] **A)** Package-level singleton in `inbound/http/shared/validator.go`:
  ```go
  var validate = validator.New()
  func ValidateRequest(req any) error { return validate.Struct(req) }
  ```
  Handlers call `shared.ValidateRequest(req)`.

- [*] **B)** Validator instance on the `Service` struct in commands/queries, injected via `SetupRouter`. Allows custom validators per context.

create a default one in the Service struct

---

## G3. Config fields (#F1)

The `config.Config` struct — what fields should bootstrap scaffold?

- [ ] **A)** Minimal production-ready:
  ```go
  type Config struct {
      DatabaseURL string
      HTTPPort    int
      LogLevel    string
  }
  ```

- [ ] **B)** Full with OTel (since you picked #4C):
  ```go
  type Config struct {
      DatabaseURL     string
      HTTPPort        int
      GRPCPort        int
      LogLevel        string
      OTelEndpoint    string
      OTelServiceName string
  }
  ```

- [*] **C)** Just the struct shape + `Load()` with `os.Getenv`. Fields are a TODO — too project-specific to pre-fill.

I would prefer to have structured like:
type Config struct {
Postgres struct { ... }
Logger struct { ... }
OTel struct { ... }
}


---

## G4. Middleware defaults (#3 + #F8)

You want a `Chain` helper + recover/requestID built-in. Should the defaults also include:

- [ ] **A)** Recover + RequestID only. Logging/tracing middleware added by user since they depend on OTel setup.
- [ ] **B)** Recover + RequestID + structured request logging (method, path, status, duration via slog).
- [*] **C)** Recover + RequestID + request logging + OTel trace propagation (extract trace from headers, set on context).
