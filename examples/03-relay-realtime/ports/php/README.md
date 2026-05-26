[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 3 — RELAY Realtime (PHP) — pending

PHP's request-per-process model makes a persistent WebSocket-driven event
loop awkward without an async runtime. To implement this pillar:

## Design options

1. **Ratchet + ReactPHP** (recommended) — long-running PHP process that
   serves both HTTP (Ratchet's HttpServer) and WS (Ratchet's IoServer).
   `SignalWire\Relay\Client` already uses an async-compatible WebSocket
   under the hood; wire its `onCall` callback to broadcast over Ratchet's
   `MessageComponentInterface`.
2. **Workerman** — alternative async runtime, similar shape.
3. **Two-process split** — keep `php -S` for HTTP, run a separate Ratchet
   process for `/ws/events`. Less elegant but simpler to set up.

Recommendation: option 1 (Ratchet + ReactPHP).

When implemented, use the Python `app.py` and TypeScript `app.ts` as
references — same shape: `/api/setup` validates creds + starts
`SignalWire\Relay\Client`; `onCall` handler broadcasts events;
`/ws/events` browser WS receives them; `/api/dial` calls `$client->dial(...)`.
