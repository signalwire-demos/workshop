# Pillar 3 — RELAY Realtime (Java)

## Run

```bash
gradle run
# Open http://localhost:8002
```

Javalin (with native WebSocket support) + `RelayClient.builder()...build()` with `onCall` handler broadcasting events to all `WsContext` subscribers.
