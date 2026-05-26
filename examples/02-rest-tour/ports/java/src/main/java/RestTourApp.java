import com.signalwire.sdk.rest.RestClient;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import io.javalin.Javalin;
import io.javalin.http.staticfiles.Location;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/** Workshop REST tour — Pillar 2 (Java). Javalin + signalwire-sdk RestClient. */
public class RestTourApp {
    private static final Gson GSON = new Gson();
    private static final Path SHARED_UI =
        Path.of(System.getProperty("user.dir"), "..", "..", "..", "..", "shared", "ui").normalize();
    private static final Map<String, String> CREDS = new HashMap<>();

    public static void main(String[] args) {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8001"));

        Javalin app = Javalin.create(cfg -> {
            cfg.staticFiles.add(staticConfig -> {
                staticConfig.directory = SHARED_UI.toString();
                staticConfig.location = Location.EXTERNAL;
                staticConfig.hostedPath = "/shared";
            });
        }).start("0.0.0.0", port);

        app.get("/", ctx -> ctx.contentType("text/html").result(
            java.nio.file.Files.newInputStream(SHARED_UI.resolve("creds-form.html"))));
        app.get("/demo.js", ctx -> ctx.contentType("application/javascript")
            .result(java.nio.file.Files.newInputStream(Path.of("demo.js"))));

        app.post("/api/setup", ctx -> {
            Map<String, String> body = GSON.fromJson(ctx.body(), new TypeToken<Map<String, String>>(){}.getType());
            String pid = body.getOrDefault("project_id", "").trim();
            String sp = body.getOrDefault("space", "").trim();
            String tk = body.getOrDefault("token", "").trim();
            if (pid.isEmpty() || sp.isEmpty() || tk.isEmpty()) {
                ctx.status(400).json(Map.of("ok", false, "error", "All fields required")); return;
            }
            try {
                RestClient.builder().project(pid).token(tk).space(sp).build()
                    .phoneNumbers().list(Map.of("limit", 1));
            } catch (Exception e) {
                ctx.status(400).json(Map.of("ok", false, "error", "Credential check failed: " + e.getMessage())); return;
            }
            CREDS.put("project_id", pid); CREDS.put("space", sp); CREDS.put("token", tk);
            ctx.json(Map.of("ok", true, "jwt", "session-validated", "subscriber_id", "n/a"));
        });

        app.get("/api/list-numbers", ctx -> {
            if (CREDS.isEmpty()) { ctx.status(400).json(Map.of("ok", false, "error", "Run setup first")); return; }
            try {
                Object resp = client().phoneNumbers().list(Map.of("limit", 20));
                ctx.json(Map.of("ok", true, "sdk_call", "client.phoneNumbers().list(Map.of(\"limit\", 20))", "response", resp));
            } catch (Exception e) { ctx.status(400).json(Map.of("ok", false, "error", e.getMessage())); }
        });

        app.post("/api/send-sms", ctx -> {
            if (CREDS.isEmpty()) { ctx.status(400).json(Map.of("ok", false, "error", "Run setup first")); return; }
            Map<String, String> body = GSON.fromJson(ctx.body(), new TypeToken<Map<String, String>>(){}.getType());
            String from = body.getOrDefault("from", "").trim();
            String to = body.getOrDefault("to", "").trim();
            String text = body.getOrDefault("body", "Hello from the SignalWire workshop!").trim();
            if (from.isEmpty() || to.isEmpty()) { ctx.status(400).json(Map.of("ok", false, "error", "from + to required")); return; }
            try {
                Object resp = client().compat().messages().create(Map.of("from", from, "to", to, "body", text));
                ctx.json(Map.of("ok", true, "sdk_call",
                    String.format("client.compat().messages().create(from=%s, to=%s, body=...)", from, to),
                    "response", resp));
            } catch (Exception e) { ctx.status(400).json(Map.of("ok", false, "error", e.getMessage())); }
        });

        app.get("/api/recent-calls", ctx -> {
            if (CREDS.isEmpty()) { ctx.status(400).json(Map.of("ok", false, "error", "Run setup first")); return; }
            try {
                Object resp = client().compat().calls().list(Map.of("pageSize", 10));
                ctx.json(Map.of("ok", true, "sdk_call", "client.compat().calls().list(Map.of(\"pageSize\", 10))", "response", resp));
            } catch (Exception e) { ctx.status(400).json(Map.of("ok", false, "error", e.getMessage())); }
        });

        app.post("/api/wire-number", ctx -> {
            if (CREDS.isEmpty()) { ctx.status(400).json(Map.of("ok", false, "error", "Run setup first")); return; }
            Map<String, String> body = GSON.fromJson(ctx.body(), new TypeToken<Map<String, String>>(){}.getType());
            String sid = body.getOrDefault("sid", "").trim();
            String voiceUrl = body.getOrDefault("voice_url", "").trim();
            if (sid.isEmpty() || voiceUrl.isEmpty()) { ctx.status(400).json(Map.of("ok", false, "error", "sid + voice_url required")); return; }
            try {
                Object resp = client().phoneNumbers().update(sid, Map.of("voice_url", voiceUrl, "voice_method", "POST"));
                ctx.json(Map.of("ok", true, "sdk_call",
                    String.format("client.phoneNumbers().update(%s, voice_url=%s)", sid, voiceUrl),
                    "response", resp));
            } catch (Exception e) { ctx.status(400).json(Map.of("ok", false, "error", e.getMessage())); }
        });

        System.out.println("REST tour listening on http://0.0.0.0:" + port);
    }

    static RestClient client() {
        return RestClient.builder()
            .project(CREDS.get("project_id"))
            .token(CREDS.get("token"))
            .space(CREDS.get("space"))
            .build();
    }
}
