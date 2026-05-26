# Pillar 1 — AI Agent (Rust) — pending

The Rust `signalwire` crate's `AgentBase::run()` boots its own internal
HTTP server and blocks. The workshop UI pattern (same-port hosting of
UI + `/agent`) needs either:

1. **Two-thread / two-port** — spawn `agent.run()` on a background
   thread bound to a sub-port, run an Axum UI app on the main port that
   reverse-proxies `/agent/*` to the sub-port. Workable but adds a
   second `tokio::spawn` + reqwest proxy boilerplate.
2. **tower-middleware feature** — `signalwire` is published with
   `default-features = ["tower-middleware"]`. There's likely an
   `axum::Router` accessor for embedding the agent into a custom Axum
   app, but it isn't yet exposed in the public API (audit
   `signalwire::agent::agent_base` for an `into_router()` or
   `as_router()` method).

Recommendation: option 2 once the SDK exposes it. Option 1 today.

When implemented, Python `app.py` is the reference.

## Quick stand-alone agent (no UI)

If you just want the agent itself running on Rust:

```rust
use signalwire::agent::AgentBase;

fn main() {
    let mut a = AgentBase::new("workshop-agent", "/agent");
    a.add_skill("datetime", serde_json::json!({}))
     .add_skill("math", serde_json::json!({}));
    // ... define_tool, DataMap registration ...
    a.run();
}
```
