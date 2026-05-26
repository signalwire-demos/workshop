import com.signalwire.sdk.rest.RestClient;
import com.signalwire.sdk.relay.RelayClient;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import io.javalin.Javalin;
import io.javalin.http.staticfiles.Location;
import io.javalin.websocket.WsContext;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/** Workshop RELAY realtime — Pillar 3 (Java). Javalin WS + RelayClient. */
public class RelayRealtimeApp {
    private static final Gson GSON = new Gson();
    private static final Path SHARED_UI =
        Path.of(System.getProperty("user.dir"), "..", "..", "..", "..", "shared", "ui").normalize();

    private static final Map<String, String> CREDS = new HashMap<>();
    private static volatile RelayClient RELAY;
    private static final Map<String, WsContext> SUBS = new ConcurrentHashMap<>();

    public static void main(String[] args) {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8002"));

        Javalin app = Javalin.create(cfg -> {
            cfg.staticFiles.add(s -> {
                s.directory = SHARED_UI.toString();
                s.location = Location.EXTERNAL;
                s.hostedPath = "/shared";
            });
        }).start("0.0.0.0", port);

        app.get("/", ctx -> ctx.contentType("text/html")
            .result(java.nio.file.Files.newInputStream(SHARED_UI.resolve("creds-form.html"))));
        app.get("/demo.js", ctx -> ctx.contentType("application/javascript")
            .result(java.nio.file.Files.newInputStream(Path.of("demo.js"))));

        app.ws("/ws/events", ws -> {
            ws.onConnect(c -> {
                SUBS.put(c.sessionId(), c);
                if (RELAY == null) c.send(GSON.toJson(Map.of("kind", "error", "message", "Run setup first")));
                else c.send(GSON.toJson(Map.of("kind", "system", "message", "ws connected")));
            });
            ws.onClose(c -> SUBS.remove(c.sessionId()));
        });

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

            // Tear down any prior relay
            RelayClient prior = RELAY;
            if (prior != null) try { prior.disconnect(); } catch (Exception ignore) {}

            RelayClient rl = RelayClient.builder()
                .project(pid).token(tk).space(sp).contexts(List.of("workshop")).build();

            rl.onCall(call -> {
                broadcast(Map.of("kind", "call", "state", "incoming", "call_id", call.getCallId()));
                try {
                    call.answer();
                    broadcast(Map.of("kind", "call", "state", "answered", "call_id", call.getCallId()));
                } catch (Exception e) {
                    broadcast(Map.of("kind", "error", "message", "answer failed: " + e.getMessage()));
                }
            });

            new Thread(() -> {
                try { rl.connect(); broadcast(Map.of("kind", "system", "message", "RELAY connected")); }
                catch (Exception e) { broadcast(Map.of("kind", "error", "message", "RELAY connect failed: " + e.getMessage())); }
            }).start();

            CREDS.put("project_id", pid); CREDS.put("space", sp); CREDS.put("token", tk);
            RELAY = rl;
            ctx.json(Map.of("ok", true, "jwt", "session-validated", "subscriber_id", "n/a"));
        });

        app.post("/api/dial", ctx -> {
            RelayClient rl = RELAY;
            if (rl == null) { ctx.status(400).json(Map.of("ok", false, "error", "Run setup first")); return; }
            Map<String, String> body = GSON.fromJson(ctx.body(), new TypeToken<Map<String, String>>(){}.getType());
            String from = body.getOrDefault("from", "").trim();
            String to = body.getOrDefault("to", "").trim();
            if (from.isEmpty() || to.isEmpty()) { ctx.status(400).json(Map.of("ok", false, "error", "from + to required")); return; }
            try {
                List<List<Map<String, Object>>> devices = List.of(List.of(
                    Map.of("type", "phone", "from", from, "to", to, "timeout", 30)
                ));
                var call = rl.dial(devices);
                ctx.json(Map.of("ok", true, "call_id", call.getCallId()));
            } catch (Exception e) { ctx.status(400).json(Map.of("ok", false, "error", e.getMessage())); }
        });

        System.out.println("RELAY realtime listening on http://0.0.0.0:" + port);
    }

    static void broadcast(Map<String, Object> event) {
        String json = GSON.toJson(event);
        for (WsContext c : SUBS.values()) {
            try { c.send(json); } catch (Exception ignore) {}
        }
    }
}
