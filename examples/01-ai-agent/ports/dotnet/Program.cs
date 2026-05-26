// Workshop AI Agent — Pillar 1 (.NET / C#).
//
// ASP.NET Core minimal API hosts UI + /api/setup + /api/wire-number on
// the main port. SignalWire AgentBase.Run() blocks, so we run it on a
// background Task bound to internal port 8081 and reverse-proxy /agent/*.

using System.Net.Http;
using System.Text.Json;
using Microsoft.AspNetCore.StaticFiles;
using SignalWire.Agent;
using SignalWire.DataMap;
using SignalWire.REST;
using SignalWire.SWAIG;

const int AgentInternalPort = 8081;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var sharedUi = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(),
    "..", "..", "..", "..", "shared", "ui"));
var state = new Dictionary<string, string>();
List<object> numbers = new();
var http = new HttpClient { BaseAddress = new Uri($"http://127.0.0.1:{AgentInternalPort}") };

// Background-spawn the agent
_ = Task.Run(() =>
{
    Environment.SetEnvironmentVariable("SWML_PORT", AgentInternalPort.ToString());
    var agent = BuildAgent();
    agent.Run();
});

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(sharedUi),
    RequestPath = "/shared",
});

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
    try
    {
        var listed = await new RestClient(pid, tk, sp).PhoneNumbers.List(new { limit = 20 });
        numbers = (listed as System.Collections.IEnumerable)?.Cast<object>().ToList() ?? new();
    }
    catch (Exception e)
    {
        return Results.BadRequest(new { ok = false, error = $"Credential check failed: {e.Message}" });
    }
    state["project_id"] = pid; state["space"] = sp; state["token"] = tk;
    return Results.Json(new { ok = true, jwt = "", subscriber_id = "", numbers, agent_path = "/agent" });
});

app.MapPost("/api/wire-number", async (HttpRequest req) =>
{
    if (state.Count == 0) return Results.BadRequest(new { ok = false, error = "Run setup first" });
    var data = await req.ReadFromJsonAsync<Dictionary<string, string>>() ?? new();
    var sid = (data.GetValueOrDefault("sid") ?? "").Trim();
    var publicUrl = (data.GetValueOrDefault("public_url") ?? "").Trim().TrimEnd('/');
    if (sid == "" || publicUrl == "") return Results.BadRequest(new { ok = false, error = "sid + public_url required" });
    var voice_url = $"{publicUrl}/agent";
    try
    {
        await new RestClient(state["project_id"], state["token"], state["space"])
            .PhoneNumbers.Update(sid, new { voice_url, voice_method = "POST" });
        return Results.Json(new { ok = true, voice_url });
    }
    catch (Exception e) { return Results.BadRequest(new { ok = false, error = e.Message }); }
});

// Reverse-proxy /agent/* → http://127.0.0.1:8081/agent/*
app.Map("/agent/{**rest}", async (HttpContext ctx) => await ProxyToAgent(ctx, http));
app.Map("/agent", async (HttpContext ctx) => await ProxyToAgent(ctx, http));

var port = int.Parse(Environment.GetEnvironmentVariable("PORT") ?? "8000");
app.Run($"http://0.0.0.0:{port}");

static async Task ProxyToAgent(HttpContext ctx, HttpClient client)
{
    var targetPath = ctx.Request.Path.Value + ctx.Request.QueryString;
    var msg = new HttpRequestMessage(new HttpMethod(ctx.Request.Method), targetPath);
    foreach (var h in ctx.Request.Headers)
    {
        if (h.Key.Equals("Host", StringComparison.OrdinalIgnoreCase)) continue;
        msg.Headers.TryAddWithoutValidation(h.Key, h.Value.ToArray());
    }
    if (ctx.Request.ContentLength > 0)
    {
        msg.Content = new StreamContent(ctx.Request.Body);
        msg.Content.Headers.TryAddWithoutValidation("Content-Type", ctx.Request.ContentType ?? "application/octet-stream");
    }
    try
    {
        var res = await client.SendAsync(msg, HttpCompletionOption.ResponseHeadersRead);
        ctx.Response.StatusCode = (int)res.StatusCode;
        foreach (var h in res.Headers) ctx.Response.Headers[h.Key] = h.Value.ToArray();
        foreach (var h in res.Content.Headers) ctx.Response.Headers[h.Key] = h.Value.ToArray();
        ctx.Response.Headers.Remove("transfer-encoding");
        await res.Content.CopyToAsync(ctx.Response.Body);
    }
    catch (Exception e)
    {
        ctx.Response.StatusCode = 502;
        await ctx.Response.WriteAsync($"agent unreachable: {e.Message}");
    }
}

static AgentBase BuildAgent()
{
    var a = new AgentBase(new AgentOptions { Name = "workshop-agent", Route = "/agent" });

    a.AddLanguage("English", "en-US", "rime.spore",
        speechFillers: new List<string> { "Um", "Well", "Sure" });

    a.PromptAddSection("Personality",
        "You are a friendly demo assistant in a SignalWire workshop. " +
        "Sound warm and natural, keep replies short.");
    a.PromptAddSection("Greeting",
        "Greet the caller, say you're the workshop demo agent, " +
        "and ask what they'd like to try.");
    a.PromptAddSection("Capabilities", "", new List<string> {
        "tell_joke — tell a dad joke from icanhazdadjoke",
        "get_weather — current weather for a city",
        "datetime — current date and time anywhere",
        "math — arithmetic, percentages, conversions",
    });

    a.AddSkill("datetime", null);
    a.AddSkill("math", null);

    a.DefineTool(
        name: "tell_joke",
        description: "Tell a fresh dad joke from the icanhazdadjoke API. " +
            "Use whenever the caller asks for a joke or wants entertainment.",
        parameters: new { type = "object", properties = new { }, required = Array.Empty<string>() },
        handler: (args, raw) =>
        {
            try
            {
                using var client = new HttpClient();
                client.DefaultRequestHeaders.Add("Accept", "application/json");
                client.DefaultRequestHeaders.Add("User-Agent", "SignalWire-Workshop");
                var json = client.GetStringAsync("https://icanhazdadjoke.com/").Result;
                var doc = JsonDocument.Parse(json);
                var joke = doc.RootElement.TryGetProperty("joke", out var j) ? j.GetString() : null;
                return new FunctionResult(joke ?? "I had a joke about UDP, but you might not get it.");
            }
            catch
            {
                return new FunctionResult("I had a joke about timeouts, but it never came back.");
            }
        });

    var weather = DataMap.Of("get_weather")
        .Description("Get the current weather for a city. Use whenever the caller asks " +
            "about weather, temperature, or conditions in any location.")
        .Parameter("city", "string", "The city name", true)
        .Webhook("GET",
            "https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json")
        .Output(new FunctionResult(
            "I'm looking up ${args.city}. Coordinates: " +
            "${response.results[0].latitude}, ${response.results[0].longitude}. " +
            "Country: ${response.results[0].country}."))
        .FallbackOutput(new FunctionResult(
            "I couldn't find weather data for ${args.city} right now."));
    a.RegisterSwaigFunction(weather.ToSwaigFunction());

    return a;
}
