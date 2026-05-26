# Pillar 3 — RELAY Realtime (Ruby) — pending

This Ruby parity port is not yet built. The challenge is that the shared
`demo.js` opens a browser WebSocket against `/ws/events`, and Sinatra
doesn't ship native WebSocket support — you need `faye-websocket-ruby` +
EventMachine or a Rack hijack.

## Design options when picking this up

1. **`faye-websocket-ruby` + EventMachine** — most idiomatic for Sinatra,
   adds two dependencies. The `Faye::WebSocket` upgrade happens inside a
   Sinatra route; events forwarded from `SignalWire::Relay::Client`'s
   `on_call` handler via an in-memory queue.
2. **Rack hijack + native `Net::HTTP` WS handshake** — zero deps but
   ~100 lines of frame-parsing boilerplate. Don't recommend.
3. **Switch to a Roda or Hanami app** for this pillar specifically — both
   have first-class WebSocket support. Breaks symmetry with Pillars 1+2's
   Sinatra stack.
4. **Server-Sent Events (SSE) instead of WS** — Sinatra supports SSE
   natively via `stream`. Would require diverging this port's `demo.js`
   to use `EventSource` instead of `WebSocket`. Loses the
   "same demo.js across languages" property.

Recommendation: Option 1 (`faye-websocket-ruby` + EventMachine).

When implemented, use the Python `app.py` and TypeScript `app.ts` as
references — same shape: `/api/setup` validates creds + starts
`SignalWire::Relay::Client`; `on_call` handler pushes events to a queue;
`/ws/events` WebSocket forwards the queue to the browser; `/api/dial`
calls `client.dial(...)`.
