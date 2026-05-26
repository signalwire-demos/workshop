[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 1 — AI Agent (Python)

Phone-answering AI agent in ~150 lines across two files (`agent.py` + `app.py`).

## Run

```bash
pip install -r requirements.txt
python app.py
# Open http://localhost:8000 in a browser (Codespaces auto-forwards)
```

Then in the browser:
1. Paste **project ID**, **space**, and **auth token** from [dashboard.signalwire.com](https://dashboard.signalwire.com).
2. The UI lists your phone numbers. Click **"Wire to agent"** next to one.
3. Call that number. The agent answers, knows time/date/math, tells dad jokes, and looks up city coordinates.

## What's in here

| File | Purpose |
|---|---|
| `agent.py` | `WorkshopAgent(AgentBase)` — the 4-capability AI agent |
| `app.py` | FastAPI host: serves the shared UI, validates creds, wires the number, runs the agent at `/agent` |
| `demo.js` | Pillar-specific UI view (number picker + wire button) |
| `requirements.txt` | `signalwire-sdk`, `fastapi`, `uvicorn`, `requests` |

## How the agent gets its 4 capabilities

```python
# 1. Built-in skill (one-liner)
self.add_skill("datetime")
self.add_skill("math")

# 2. Custom SWAIG function (you write the handler)
self.define_tool(
    name="tell_joke",
    description="Tell a fresh dad joke.",
    parameters={"type": "object", "properties": {}, "required": []},
    handler=tell_joke,  # ← your function
)

# 3. DataMap (declarative, runs server-side, no handler)
weather = (
    DataMap("get_weather")
    .parameter("city", "string", "City name", required=True)
    .webhook("GET", "https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1")
    .output(FunctionResult("Coordinates for ${args.city}: ..."))
)
self.register_swaig_function(weather.to_swaig_function())
```
