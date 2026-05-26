[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 2 — REST Tour (Python)

## Run

```bash
pip install -r requirements.txt
python app.py
# Open http://localhost:8001 (Codespaces auto-forwards)
```

Paste creds → 4 buttons appear. Each shows the SDK call and the response side by side.

## What you'll exercise

| Button | SDK call |
|---|---|
| List my phone numbers | `client.phone_numbers.list(limit=20)` |
| Send a test SMS | `client.compat.messages.create(from_=..., to=..., body=...)` |
| Show recent calls | `client.compat.calls.list(page_size=10)` |
| Point a number at an agent | `client.phone_numbers(sid).update(voice_url=...)` |

Same `RestClient` your AI agent uses for the SignalWire APIs.
