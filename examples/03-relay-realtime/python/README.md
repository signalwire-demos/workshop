# Pillar 3 — RELAY Realtime (Python)

## Run

```bash
pip install -r requirements.txt
python app.py
# Open http://localhost:8002
```

Paste creds → backend opens a RELAY WebSocket connection to SignalWire in the background → UI shows a live event feed and a "Place outbound call" button.

## What you'll see

| Event source | What appears in the feed |
|---|---|
| Incoming call to your SignalWire number | `{kind: "call", state: "incoming", ...}` then `{state: "answered"}` |
| Outbound dial (button) | `{kind: "dial", call_id, from, to}` |
| Errors / disconnects | `{kind: "error" | "system", ...}` |

## How it works

| Piece | What it does |
|---|---|
| `RelayClient(project, token, host, contexts=["workshop"])` | Opens a WS to SignalWire RELAY. |
| `@client.on_call` decorator | Receives incoming-call events; pushes them into a queue. |
| `client.dial(devices, dial_timeout=60.0)` | Places outbound calls. |
| FastAPI `WebSocket` route | Forwards queue → browser. |

This is the push side of SignalWire. REST (Pillar 2) is for setup. RELAY (Pillar 3) is for reacting live.
