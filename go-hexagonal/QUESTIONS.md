# Questions — go-hexagonal template review follow-up

**Status:** Answered 2026-04-14. Implementation in progress — rewriting all TODOs across the template (D1=c) with the `TODO(scaffolding):` schema.

The review identified three structural gaps that cap the scoring ceiling because they leave intentional TODOs/stubs in the generated code. These questions drove the decision to adopt a uniform, detailed TODO schema instead of adding specialized scaffolding commands or hardcoding a specific auth/broker choice.

---

## Q1. `ActorFromRequest` is stubbed → blocks security criterion 7

**Answer:** D2=b (method-agnostic TODO listing JWT / header / session options with the specifics each would need). Kept stub, enriched the TODO. No specialized `add_actor_extraction` command.

---

## Q2. `Backend` in outbound adapters is empty → caps integration criterion 25/26

**Answer:** Kept stub, enriched TODOs. `Backend` interface now documents the expected method shape for kafka / sqs / nats; `Publish*` methods now document serialize-and-publish responsibilities. No specialized `add_kafka_backend` command.

---

## Q3. Nominal TODOs in `init.go.tmpl`

**Answer:** D5=a — same `TODO(scaffolding):` detailed treatment as the stubs. No non-TODO rephrasing.

---

## Q4. `audit-security.md` false-positives on the `RegisterWire` / `wireFuncs` extension pattern

**Answer:** Deferred — out of scope for this template edit.

---

## Q5. Scope of this round

**Answer:** D1=c (rewrite all ~60 TODOs including `t.Skip`, worker stub, structural placeholders, nominal migration/backend TODOs).

---

## TODO schema applied everywhere (agreed 2026-04-14)

Every TODO in the template now follows this shape:

```
// TODO(scaffolding): <what to do, one line action>.
// Required before <site-specific blocker — what test/feature this unblocks>.
// <How: concrete steps, names, types, SQL fragments, method signatures>.
```

**D1:** c — all ~60 sites.
**D2:** b — method-agnostic: list JWT / header / session with the fields each would need.
**D3:** a — site-specific blocker phrasing ("Required before publishers can emit events", "Required before FindByID returns real data", etc.).
**D4:** `TODO(scaffolding)` prefix everywhere.
**D5:** a — same detailed treatment for nominal TODOs (backends extension point, migrations runner, etc.).
