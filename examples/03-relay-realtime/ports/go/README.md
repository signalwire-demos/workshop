[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 3 — RELAY Realtime (Go)

## Run

```bash
go mod tidy
go run .
# Open http://localhost:8002
```

`net/http` + `gorilla/websocket` for the browser WS. `relay.Client` (with functional options) for the SignalWire connection. `OnCall` handler pushes events to all subscribed browser WSes.
