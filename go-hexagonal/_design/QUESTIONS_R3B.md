# Review Round 3B — Outbox design details

## Q1: Outbox adapter — UoW integration or standalone?

The outbox adapter writes events to an `outbox_events` table in the same DB transaction as the domain operation. Two patterns:

**Option A: UoW-integrated** — The outbox adapter receives the `*sql.Tx` from the UoW and writes within the same transaction. Requires the app service to use `uow.Do()` wrapping both the repo write and the outbox write.
```go
type OutboxPublisher struct { /* no pool — gets tx from context or param */ }
func (p *OutboxPublisher) Publish(ctx context.Context, tx pgx.Tx, event OutboxEvent) error
```

**Option B: Standalone with pool** — The outbox adapter has its own pool and opens its own transaction. Simpler to scaffold but doesn't guarantee atomicity with the domain write (defeats the purpose of outbox).

- [x] Option A: UoW-integrated (requires existing add_domain_uow)
- [ ] Option B: Standalone (simpler but loses atomicity guarantee)
- [ ] Other: ___

## Q2: Relay worker — polling or pg LISTEN/NOTIFY?

The relay reads unpublished events from `outbox_events` and forwards them to the message broker.

- [ ] Polling (simple `SELECT ... WHERE published = false ORDER BY created_at LIMIT N`) — portable, works with any Postgres setup
- [ ] LISTEN/NOTIFY — lower latency but more complex, Postgres-specific
- [ ] Just scaffold the polling skeleton, add a hint for LISTEN/NOTIFY optimization
- [ ] Other: ___

I would prefer to have polling but outbox must be used only if sent failed

## Q3: Outbox event table schema

Proposed migration:

```sql
CREATE TABLE outbox_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate   TEXT NOT NULL,          -- e.g. "order", "invoice"
    event_type  TEXT NOT NULL,          -- e.g. "created", "deleted"
    payload     JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    published   BOOLEAN NOT NULL DEFAULT false,
    published_at TIMESTAMPTZ
);

CREATE INDEX idx_outbox_unpublished ON outbox_events (created_at) WHERE published = false;
```

- [x] Looks good
- [ ] Changes: ___

## Q4: `add_outbox` composite — what commands does it chain?

Proposed composite:
1. `add_migration` — creates the `outbox_events` table migration
2. New `add_outbox_adapter` — creates `outbound/{Adapter}/outbox.go` (writes to outbox table via UoW tx)
3. `add_cmd` with Binary=outbox-relay — creates `cmd/outbox-relay/main.go` (polling loop, publishes to broker)

The outbox adapter implements the same `{{ .Entity }}Publisher` interface from `domain/publishers/`, so existing app code doesn't change — you just swap the real publisher adapter for the outbox one in the composition root.

- [x] Yes, this decomposition works
- [ ] Changes: ___
