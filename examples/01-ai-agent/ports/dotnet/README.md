# Pillar 1 — AI Agent (.NET / C#)

```bash
dotnet run
# Open http://localhost:8000
```

## Architecture

`SignalWire.Sdk` AgentBase.Run() blocks its own Kestrel. This port hosts
the workshop UI on minimal API (port 8000) and reverse-proxies `/agent/*`
to the AgentBase on internal port 8081 via `HttpClient`.

```
browser  →  :8000 (ASP.NET Core minimal API: UI + /api/setup + wire-number)
                ↓ /agent/*
            127.0.0.1:8081 (SignalWire.Sdk AgentBase)
```
