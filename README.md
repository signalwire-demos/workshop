# SignalWire Workshop

Three pillars in ~90 minutes: **AI Agent**, **REST**, and **RELAY**. Pick a language, fork, paste your SignalWire credentials, build.

---

## Quick start

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop)
[![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

Both deploys spin up a dev environment with all 10 SDK runtimes pre-installed. Pick the example you want, run it, paste your project ID / space / auth token in the browser UI, and you're live.

You need:
- A **SignalWire account** ([signup](https://signalwire.com/signup)) — note your **project ID**, **space** (e.g., `yourname.signalwire.com`), and an **API auth token**.
- A **phone number** in your SignalWire project (for the AI Agent pillar).

No local installs, no Docker, no ngrok.

---

## What you build

| Pillar | Example dir | What it does |
|---|---|---|
| 1. **AI Agent** | [`examples/01-ai-agent/`](examples/01-ai-agent/) | Phone-answering AI assistant with 4 capabilities (greeting, datetime, joke, weather). |
| 2. **REST** | [`examples/02-rest-tour/`](examples/02-rest-tour/) | Programmatic tour: list phone numbers, send SMS, fetch call history, wire a number to your agent. |
| 3. **RELAY** | [`examples/03-relay-realtime/`](examples/03-relay-realtime/) | Live event stream from the WebSocket protocol — transcripts, call events, place outbound calls. |

Each example ships with a small web UI. You paste your credentials once, the backend creates a workshop subscriber and mints a JWT, and the demo runs.

---

## Pick your language

Each pillar is implemented in all 10 SDKs:

| Language | Install | Example path |
|---|---|---|
| Python | `pip install signalwire-sdk` | `examples/*/python/` |
| TypeScript | `npm install @signalwire/sdk` | `examples/*/typescript/` |
| Ruby | `gem install signalwire` | `examples/*/ruby/` |
| Go | `go get github.com/signalwire/signalwire-go` | `examples/*/go/` |
| Java | Maven Central `com.signalwire:signalwire-sdk` | `examples/*/java/` |
| Perl | `cpanm SignalWire` | `examples/*/perl/` |
| Rust | `cargo add signalwire-sdk` (imports as `use signalwire::...`) | `examples/*/rust/` |
| PHP | `composer require signalwire/sdk` | `examples/*/php/` |
| .NET | `dotnet add package SignalWire.Sdk` | `examples/*/dotnet/` |
| C++ | CMake build from source (CLI only) | `examples/*/cpp/` |

**Live workshop body:** Python. **Closing demo:** TypeScript showing identical code in a different language. All others are reference / bonus.

---

## Run an example locally

```bash
# Pick an example + language
cd examples/01-ai-agent/python

# Install deps (signalwire-sdk + a web framework)
pip install -r requirements.txt

# Run
python app.py
# Open http://localhost:8000 — paste creds, watch it work.
```

Same shape across languages: each `examples/*/<lang>/` directory has its own `README.md` and `requirements.txt`-equivalent.

---

## Instructor lab

Running this as a taught workshop? See [`LAB.md`](LAB.md) for the 90-minute walkthrough.

---

## Legacy workshop

The previous Docker-based 10-language workshop is preserved on the `legacy-archive` branch: `git checkout legacy-archive`.
