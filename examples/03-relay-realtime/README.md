# Pillar 3 — RELAY (Real-time)

Connect to the SignalWire RELAY WebSocket protocol. Stream live events, transcripts, and place outbound calls from the UI.

## What the demo shows

- **WS connect** — backend opens a persistent connection using the workshop subscriber's JWT.
- **Event stream** — incoming calls, ringing, answered, ended events appear live in the UI feed.
- **Live transcripts** — speak into a connected call, see ASR text arrive in real time.
- **Outbound call** — button in the UI dials a number programmatically via RELAY.

## Why RELAY (vs REST)

| | REST | RELAY |
|---|---|---|
| Trigger | Your request → SignalWire | SignalWire → your service (push) |
| Latency | ~100ms per request | Event delivery is push, ~10ms |
| Use cases | Provisioning, history, config | Live monitoring, real-time UI, AI mid-call hooks |

REST is what you use *to set things up*. RELAY is what you use *to react to what's happening*.

## Per-language implementations

Same layout. Python reference + TypeScript closing + 7 parity ports. C++ is CLI-only here too (WebSocket events stream to stdout).
