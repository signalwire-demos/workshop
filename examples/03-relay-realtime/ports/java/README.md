[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 3 — RELAY Realtime (Java)

## Run

```bash
gradle run
# Open http://localhost:8002
```

Javalin (with native WebSocket support) + `RelayClient.builder()...build()` with `onCall` handler broadcasting events to all `WsContext` subscribers.
