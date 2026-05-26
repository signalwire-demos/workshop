# Instructor Lab — 90 Minute Walkthrough

Run this end-to-end as a live workshop. Hard cap: **110 min** (10-min buffer for the inevitable phone-number-config snag).

---

## Block 0 — Welcome + setup (10 min)

- Open the [README](README.md) → click **"Open in GitHub Codespaces"** (or **"Run on Replit"**).
- While containers boot: walk through SignalWire signup → grab project ID, space, auth token.
- Buy a phone number in the SignalWire dashboard (or use the workshop pool number if provided).

**Checkpoint:** every attendee has a running dev environment in their browser tab.

---

## Block 1 — AI Agent (35 min)

```bash
cd examples/01-ai-agent/python
pip install -r requirements.txt
python app.py
```

Browser auto-opens to port 8000. Paste creds → subscriber created → demo loads.

- **5 min:** explain SWML, SWAIG, agent lifecycle.
- **10 min:** look at `agent.py` greeting + datetime skill (`agent.add_skill("datetime")`).
- **10 min:** add a custom SWAIG function (`@agent.tool(...)` decorator) — joke API.
- **10 min:** add a DataMap for weather (no code, just declaration).
- **Live call:** dial your phone number, hear the agent. Try all 4 capabilities.

**Checkpoint:** everyone's agent answers a real phone call.

---

## Block 2 — REST tour (25 min)

```bash
cd ../../02-rest-tour/python
python app.py
```

Same UI shell, port 8001.

- **10 min:** "list phone numbers", "send SMS" — instant gratification.
- **10 min:** "fetch call history" — show the call from Block 1 appearing in the list.
- **5 min:** "point a number at my agent" — programmatically wire the number to the Block 1 agent.

**Checkpoint:** everyone sent themselves an SMS from their account.

---

## Block 3 — RELAY realtime (25 min)

```bash
cd ../../03-relay-realtime/python
python app.py
```

Port 8002.

- **5 min:** explain push vs poll, WebSocket protocol overview.
- **15 min:** start the demo, dial the number, watch events stream. Speak — see transcripts appear.
- **5 min:** click "place outbound call" — phone rings, demonstrate.

**Checkpoint:** everyone saw a transcript appear in their UI mid-call.

---

## Block 4 — Closing TypeScript demo + Q&A (10 min)

```bash
cd ../../01-ai-agent/typescript
npm install
npm start
```

Same UI, same agent behavior — identical code translated to TypeScript. Pitch: "10 SDKs, one API surface, same examples in your favorite language."

Open Q&A.

---

## Pre-workshop checks (run the day-of)

```bash
bash scripts/smoke.sh
```

This validates each example boots and answers /api/setup successfully against the porting-sdk mock servers. If any example fails the smoke, fix before the workshop starts.

---

## Common snags

| Symptom | Fix |
|---|---|
| "Set up and launch" fails with 401 | Project ID / token mismatch — re-copy from dashboard, no whitespace. |
| Phone rings but agent says nothing | Number's voice webhook not wired — use Pillar 2's "point number at agent" button. |
| RELAY events don't appear | WebSocket blocked by firewall. Tell attendees to switch to Codespaces. |
| Replit free tier sleeps mid-demo | Refresh the repl URL — it wakes back up in ~10s. |
