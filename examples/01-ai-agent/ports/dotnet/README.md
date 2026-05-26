# Pillar 1 — AI Agent (.NET) — partial

The .NET `SignalWire.Sdk` AgentBase boots its own Kestrel server internally
via `agent.Run()`. The workshop UI pattern (same-port hosting of UI +
`/agent`) needs the same kind of integration discussion as the Rust port:

1. **Two-process / two-port** — spawn the agent on a worker `Task` bound
   to a sub-port, run the workshop UI as a minimal API ASP.NET Core app
   on the main port and reverse-proxy `/agent/*`.
2. **Embed via IEndpointRouteBuilder** — if the .NET SDK exposes an
   `IEndpointRouteBuilder.MapAgent(agent, "/agent")` extension, mount it
   directly. Confirm by checking the SDK release notes.

Once decided, the WorkshopAgent shape is:

```csharp
using SignalWire.Agent;
using SignalWire.DataMap;
using SignalWire.SWAIG;

var agent = new AgentBase(new AgentOptions { Name = "workshop-agent", Route = "/agent" });
agent.AddLanguage(name: "English", code: "en-US", voice: "rime.spore", speechFillers: new[] {"Um","Well"});
agent.PromptAddSection("Personality", "...");
agent.AddSkill("datetime", null);
agent.AddSkill("math", null);
agent.DefineTool(name: "tell_joke", description: "...", parameters: new {...}, handler: (args, raw) => new FunctionResult("..."));

// register DataMap for weather (same pattern as Python)
```

Pillar 2 (REST tour) in this directory is the fully-implemented .NET
example; reuse its ASP.NET Core scaffold here once the agent integration
pattern is settled.
