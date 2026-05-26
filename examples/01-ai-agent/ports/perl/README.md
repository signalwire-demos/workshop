[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 1 — AI Agent (Perl)

## Run

```bash
cpanm --installdeps .
perl app.pl daemon -l http://0.0.0.0:8000
# Open http://localhost:8000
```

Mojolicious::Lite app + `SignalWire::Agent::AgentBase`. Mojolicious's `under '/agent'` route forwards to the agent's request handler.
