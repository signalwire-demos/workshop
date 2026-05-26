// Workshop REST tour — Pillar 2 (.NET / C#).
// ASP.NET Core minimal API + SignalWire.Sdk RestClient.

using SignalWire.REST;
using Microsoft.AspNetCore.StaticFiles;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var sharedUi = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(),
    "..", "..", "..", "..", "shared", "ui"));

app.UseStaticFiles(new StaticFileOptions {
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(sharedUi),
    RequestPath = "/shared"
});

var state = new Dictionary<string, string>();
RestClient Client() => new(state["project_id"], state["token"], state["space"]);

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
    state["project_id"] = pid; state["space"] = sp; state["token"] = tk;
    return Results.Json(new { ok = true, jwt = "session-validated", subscriber_id = "n/a" });
});

app.MapGet("/api/list-numbers", async () =>
{
    if (state.Count == 0) return Results.BadRequest(new { ok = false, error = "Run setup first" });
    try {
        var resp = await Client().PhoneNumbers.List(new { limit = 20 });
        return Results.Json(new { ok = true, sdk_call = "client.PhoneNumbers.List(new { limit = 20 })", response = resp });
    } catch (Exception e) { return Results.BadRequest(new { ok = false, error = e.Message }); }
});

app.MapPost("/api/send-sms", async (HttpRequest req) =>
{
    if (state.Count == 0) return Results.BadRequest(new { ok = false, error = "Run setup first" });
    var data = await req.ReadFromJsonAsync<Dictionary<string, string>>() ?? new();
    var from = (data.GetValueOrDefault("from") ?? "").Trim();
    var to = (data.GetValueOrDefault("to") ?? "").Trim();
    var body = (data.GetValueOrDefault("body") ?? "Hello from the SignalWire workshop!").Trim();
    if (from == "" || to == "") return Results.BadRequest(new { ok = false, error = "from + to required" });
    try {
        var resp = await Client().Compat.Messages.Create(new { from, to, body });
        return Results.Json(new { ok = true, sdk_call = $"client.Compat.Messages.Create(new {{ from = {from}, to = {to}, body = ... }})", response = resp });
    } catch (Exception e) { return Results.BadRequest(new { ok = false, error = e.Message }); }
});

app.MapGet("/api/recent-calls", async () =>
{
    if (state.Count == 0) return Results.BadRequest(new { ok = false, error = "Run setup first" });
    try {
        var resp = await Client().Compat.Calls.List(new { pageSize = 10 });
        return Results.Json(new { ok = true, sdk_call = "client.Compat.Calls.List(new { pageSize = 10 })", response = resp });
    } catch (Exception e) { return Results.BadRequest(new { ok = false, error = e.Message }); }
});

app.MapPost("/api/wire-number", async (HttpRequest req) =>
{
    if (state.Count == 0) return Results.BadRequest(new { ok = false, error = "Run setup first" });
    var data = await req.ReadFromJsonAsync<Dictionary<string, string>>() ?? new();
    var sid = (data.GetValueOrDefault("sid") ?? "").Trim();
    var voice_url = (data.GetValueOrDefault("voice_url") ?? "").Trim();
    if (sid == "" || voice_url == "") return Results.BadRequest(new { ok = false, error = "sid + voice_url required" });
    try {
        var resp = await Client().PhoneNumbers.Update(sid, new { voice_url, voice_method = "POST" });
        return Results.Json(new { ok = true, sdk_call = $"client.PhoneNumbers.Update({sid}, new {{ voice_url = {voice_url} }})", response = resp });
    } catch (Exception e) { return Results.BadRequest(new { ok = false, error = e.Message }); }
});

var port = int.Parse(Environment.GetEnvironmentVariable("PORT") ?? "8001");
app.Run($"http://0.0.0.0:{port}");
