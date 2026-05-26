// Workshop RELAY realtime — Pillar 3 (.NET / C#).
//
// ASP.NET Core minimal API + WebSockets + SignalWire.Relay.Client.

using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading.Channels;
using Microsoft.AspNetCore.StaticFiles;
using SignalWire.REST;
using SignalWire.Relay;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.UseWebSockets();

var sharedUi = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(),
    "..", "..", "..", "..", "shared", "ui"));
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(sharedUi),
    RequestPath = "/shared",
});

var state = new Dictionary<string, string>();
Client? relay = null;
var subs = new HashSet<WebSocket>();
var subsLock = new object();

void Broadcast(object evt)
{
    var json = JsonSerializer.Serialize(evt);
    var bytes = Encoding.UTF8.GetBytes(json);
    lock (subsLock)
    {
        var dead = new List<WebSocket>();
        foreach (var ws in subs)
        {
            try { ws.SendAsync(bytes, WebSocketMessageType.Text, true, default).Wait(); }
            catch { dead.Add(ws); }
        }
        foreach (var d in dead) subs.Remove(d);
    }
}

app.MapGet("/", () => Results.File(Path.Combine(sharedUi, "creds-form.html"), "text/html"));
app.MapGet("/demo.js", () => Results.File("demo.js", "application/javascript"));

app.MapPost("/api/setup", async (HttpRequest req) =>
{
    var data = await req.ReadFromJsonAsync<Dictionary<string, string>>() ?? new();
    var pid = (data.GetValueOrDefault("project_id") ?? "").Trim();
    var sp = (data.GetValueOrDefault("space") ?? "").Trim();
    var tk = (data.GetValueOrDefault("token") ?? "").Trim();
    if (pid == "" || sp == "" || tk == "")
        return Results.BadRequest(new { ok = false, error = "All fields required" });
    try { await new RestClient(pid, tk, sp).PhoneNumbers.List(new { limit = 1 }); }
    catch (Exception e) { return Results.BadRequest(new { ok = false, error = $"Credential check failed: {e.Message}" }); }

    if (relay != null) { try { await relay.Disconnect(); } catch { } }

    state["project_id"] = pid; state["space"] = sp; state["token"] = tk;
    var rl = new Client(new ClientOptions
    {
        Project = pid, Token = tk, Space = sp, Contexts = new[] { "workshop" }
    });
    rl.OnCall(async (call) =>
    {
        Broadcast(new { kind = "call", state = "incoming", call_id = call.CallId });
        try
        {
            await call.Answer();
            Broadcast(new { kind = "call", state = "answered", call_id = call.CallId });
        }
        catch (Exception e)
        {
            Broadcast(new { kind = "error", message = $"answer failed: {e.Message}" });
        }
    });
    _ = Task.Run(async () =>
    {
        try { await rl.Connect(); Broadcast(new { kind = "system", message = "RELAY connected" }); }
        catch (Exception e) { Broadcast(new { kind = "error", message = $"RELAY connect failed: {e.Message}" }); }
    });
    relay = rl;
    return Results.Json(new { ok = true, jwt = "session-validated", subscriber_id = "n/a" });
});

app.MapPost("/api/dial", async (HttpRequest req) =>
{
    if (relay == null) return Results.BadRequest(new { ok = false, error = "Run setup first" });
    var data = await req.ReadFromJsonAsync<Dictionary<string, string>>() ?? new();
    var from = (data.GetValueOrDefault("from") ?? "").Trim();
    var to = (data.GetValueOrDefault("to") ?? "").Trim();
    if (from == "" || to == "") return Results.BadRequest(new { ok = false, error = "from + to required" });
    try
    {
        var devices = new List<List<Dictionary<string, object>>> {
            new() { new() {
                { "type", "phone" }, { "from", from }, { "to", to }, { "timeout", 30 }
            } }
        };
        var call = await relay.Dial(devices);
        return Results.Json(new { ok = true, call_id = call.CallId });
    }
    catch (Exception e) { return Results.BadRequest(new { ok = false, error = e.Message }); }
});

app.Map("/ws/events", async (HttpContext ctx) =>
{
    if (!ctx.WebSockets.IsWebSocketRequest)
    {
        ctx.Response.StatusCode = 400;
        return;
    }
    var ws = await ctx.WebSockets.AcceptWebSocketAsync();
    lock (subsLock) subs.Add(ws);
    var opener = relay != null
        ? JsonSerializer.Serialize(new { kind = "system", message = "ws connected" })
        : JsonSerializer.Serialize(new { kind = "error", message = "Run setup first" });
    await ws.SendAsync(Encoding.UTF8.GetBytes(opener), WebSocketMessageType.Text, true, default);
    var buf = new byte[1024];
    while (ws.State == WebSocketState.Open)
    {
        try
        {
            var r = await ws.ReceiveAsync(buf, default);
            if (r.MessageType == WebSocketMessageType.Close) break;
        }
        catch { break; }
    }
    lock (subsLock) subs.Remove(ws);
});

var port = int.Parse(Environment.GetEnvironmentVariable("PORT") ?? "8002");
app.Run($"http://0.0.0.0:{port}");
