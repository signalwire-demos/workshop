[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 1 — AI Agent (Java)

## Run

```bash
gradle run
# Open http://localhost:8000
```

## How it integrates

Java's `AgentBase` uses `com.sun.net.httpserver.HttpServer` internally. We extend `AgentBase` and override the protected `registerAdditionalRoutes(server)` hook to mount the workshop UI on the same HTTP server that hosts the agent — single port, single process.

Build pulls from Maven Central: `com.signalwire:signalwire-sdk:2.0.2`.

## Naming differences

| Python | Java |
|---|---|
| `add_skill("datetime")` | `agent.addSkill("datetime", null)` |
| `define_tool(name=..., handler=...)` | `agent.defineTool(name, description, params, handler)` |
| `DataMap("get_weather").parameter(...)` | `DataMap.of("get_weather").parameter(...)` |
| `RestClient(project=..., token=..., host=...)` | `RestClient.builder().project(...).token(...).space(...).build()` |
