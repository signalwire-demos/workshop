[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 3 — RELAY Realtime (Rust) — pending

Rust port pending. Sketch:

```rust
use axum::extract::ws::{WebSocket, WebSocketUpgrade};
use signalwire::relay::client::Client;

// On /api/setup: build Client, register on_call handler that broadcasts
// to a tokio::sync::broadcast channel. /ws/events subscribes the browser
// WS to that channel. /api/dial forwards to client.dial(...).
```

Axum has first-class WebSocket support; `signalwire::relay::client::Client`
exposes async `connect()`, `on_call()`, and `dial()`. The Pillar 2 REST
tour code in this directory shows the Axum + signalwire RestClient
pattern that's reusable here.
