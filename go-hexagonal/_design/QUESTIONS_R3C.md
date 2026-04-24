# Review Round 3C — Outbox publish strategy

## Q1: Direct-first vs always-outbox

Your answer says "outbox must be used only if send failed." Two interpretations:

**Option A: Direct-first with outbox fallback**
The publisher adapter tries to publish directly to the broker. If that fails, it writes to the `outbox_events` table (within the UoW tx). The relay worker picks up only failed events later.

```
app.Create() → uow.Do(tx) {
    repo.Create(tx, entity)
    err := publisher.Publish(ctx, event)  // try broker directly
    if err != nil {
        outbox.Write(tx, event)           // fallback to outbox
    }
}
```

**Tradeoff**: Faster happy path (no outbox write), but dual-write risk — if the broker ACKs but the DB tx rolls back, the event is published but the entity doesn't exist. This is the exact problem the classic outbox solves.

**Option B: Always-outbox, relay publishes immediately**
Always write to the outbox table in the same tx. The relay runs on a tight polling loop (e.g. 100ms) and publishes + marks as done. No dual-write risk. Events are slightly delayed but guaranteed consistent.

```
app.Create() → uow.Do(tx) {
    repo.Create(tx, entity)
    outbox.Write(tx, event)               // always write to outbox
}
// relay (separate goroutine/process) picks up and publishes
```

**Option C: Always-outbox, but try direct publish optimistically after commit**
Write to outbox in tx (guarantees delivery). After tx commits, *also* try direct publish. If it succeeds, mark the outbox row as published immediately. The relay only handles the rare failure case. Best of both worlds: consistency + low latency.

```
app.Create() → uow.Do(tx) {
    repo.Create(tx, entity)
    outbox.Write(tx, event)               // guarantee
}
// after commit:
if publisher.Publish(ctx, event) == nil {
    outbox.MarkPublished(event.ID)        // skip relay for this one
}
```

- [*] Option A: Direct-first with outbox fallback (accepts dual-write risk)
- [ ] Option B: Always-outbox (safest, slightly higher latency)
- [ ] Option C: Always-outbox + optimistic direct publish after commit (safe + fast)
- [ ] Other: ___
