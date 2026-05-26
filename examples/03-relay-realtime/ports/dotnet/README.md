# Pillar 3 — RELAY Realtime (.NET / C#) — pending

ASP.NET Core has first-class WebSocket support (`app.UseWebSockets()`),
and `SignalWire.Relay.Client` has the same `OnCall`/`Connect`/`Dial`
shape as the other ports. Sketch:

```csharp
using SignalWire.Relay;

app.UseWebSockets();
app.Map("/ws/events", async (HttpContext ctx) => {
    if (!ctx.WebSockets.IsWebSocketRequest) { ctx.Response.StatusCode = 400; return; }
    var ws = await ctx.WebSockets.AcceptWebSocketAsync();
    // ... subscribe ws to event channel, forward Relay events
});

app.MapPost("/api/setup", async (HttpRequest req) => {
    // build SignalWire.Relay.Client(project, token, space, contexts: ["workshop"])
    // register OnCall handler that publishes to channel
    // background-task client.Connect()
});

app.MapPost("/api/dial", async (HttpRequest req) => {
    // client.Dial(devices: [[{type: "phone", from, to, timeout: 30}]])
});
```

The Pillar 2 REST tour in this directory shows the ASP.NET Core minimal API + `SignalWire.Sdk` pattern that's reusable here.
