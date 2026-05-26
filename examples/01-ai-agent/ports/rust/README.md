[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 1 — AI Agent (Rust)

```bash
cargo run --release
# Open http://localhost:8000
```

## Architecture

The `signalwire` crate's `AgentBase::run()` blocks its own HTTP server.
This port hosts the workshop UI on Axum (port 8000) and reverse-proxies
`/agent/*` to the AgentBase on an internal port (8081) via `reqwest`.

```
browser  →  :8000 (Axum: UI + /api/setup + /api/wire-number)
                ↓ /agent/*
            127.0.0.1:8081 (signalwire AgentBase)
```

If a future SDK release exposes an `axum::Router` accessor (via the
`tower-middleware` feature), this can collapse to a single process with
`Router::nest("/agent", agent.into_router())`.
