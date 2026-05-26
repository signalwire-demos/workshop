[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 1 — AI Agent (Go)

## Run

```bash
go mod tidy
go run .
# Open http://localhost:8000
```

Pure `net/http` — no web framework. The workshop UI is served from a custom `http.ServeMux`; the agent's HTTP handler is mounted via `AgentBase.AsRouter()` at `/agent/`.

## Naming differences from Python

| Python | Go |
|---|---|
| `add_skill("datetime")` | `a.AddSkill("datetime", nil)` |
| `define_tool(name=..., handler=...)` | `a.DefineTool(agent.ToolDefinition{Name: ..., Handler: ...})` |
| `DataMap("get_weather").parameter(...)` | `datamap.NewDataMap("get_weather").Parameter(...)` |
| `client.fabric.create_subscriber_token(...)` | (Go SDK lacks subscriber-token helper — out of scope) |

Idiomatic Go: functional options for constructors (`agent.WithName`, `agent.WithRoute`), explicit error returns, value vs pointer receivers.
