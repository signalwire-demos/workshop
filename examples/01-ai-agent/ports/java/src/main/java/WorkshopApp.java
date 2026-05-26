import com.signalwire.sdk.agent.AgentBase;
import com.signalwire.sdk.rest.RestClient;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Workshop AI Agent app — Pillar 1 (Java).
 *
 * Uses com.sun.net.httpserver (zero-dep stdlib) and overrides
 * AgentBase.registerAdditionalRoutes() to mount the workshop UI on
 * the same HttpServer that hosts the agent.
 */
public class WorkshopApp {
    private static final Gson GSON = new Gson();
    private static final Path SHARED_UI =
        Path.of(System.getProperty("user.dir"), "..", "..", "..", "..", "shared", "ui").normalize();
    private static final Map<String, String> STATE = new HashMap<>();
    private static volatile List<Map<String, Object>> NUMBERS = List.of();

    public static void main(String[] args) throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8000"));

        AgentBase agent = new WorkshopAgent() {
            @Override
            protected void registerAdditionalRoutes(HttpServer server) {
                server.createContext("/shared/", new StaticFileHandler(SHARED_UI, "/shared/"));
                server.createContext("/", new RootHandler());
                server.createContext("/demo.js", new FileHandler(Path.of("demo.js"), "application/javascript"));
                server.createContext("/api/setup", new SetupHandler());
                server.createContext("/api/wire-number", new WireNumberHandler());
            }
        };

        agent.setPort(port);
        System.out.println("AI Agent listening on http://0.0.0.0:" + port);
        agent.run();
    }

    static class RootHandler implements HttpHandler {
        public void handle(HttpExchange ex) throws IOException {
            if (!"/".equals(ex.getRequestURI().getPath())) {
                ex.sendResponseHeaders(404, -1);
                return;
            }
            byte[] body = Files.readAllBytes(SHARED_UI.resolve("creds-form.html"));
            ex.getResponseHeaders().add("Content-Type", "text/html");
            ex.sendResponseHeaders(200, body.length);
            try (OutputStream os = ex.getResponseBody()) { os.write(body); }
        }
    }

    static class FileHandler implements HttpHandler {
        final Path path;
        final String contentType;
        FileHandler(Path p, String ct) { this.path = p; this.contentType = ct; }
        public void handle(HttpExchange ex) throws IOException {
            byte[] body = Files.readAllBytes(path);
            ex.getResponseHeaders().add("Content-Type", contentType);
            ex.sendResponseHeaders(200, body.length);
            try (OutputStream os = ex.getResponseBody()) { os.write(body); }
        }
    }

    static class StaticFileHandler implements HttpHandler {
        final Path root;
        final String prefix;
        StaticFileHandler(Path r, String p) { this.root = r; this.prefix = p; }
        public void handle(HttpExchange ex) throws IOException {
            String reqPath = ex.getRequestURI().getPath();
            String rel = reqPath.startsWith(prefix) ? reqPath.substring(prefix.length()) : reqPath;
            Path file = root.resolve(rel).normalize();
            if (!file.startsWith(root) || !Files.exists(file)) {
                ex.sendResponseHeaders(404, -1); return;
            }
            byte[] body = Files.readAllBytes(file);
            String ct = rel.endsWith(".css") ? "text/css"
                : rel.endsWith(".js") ? "application/javascript"
                : rel.endsWith(".html") ? "text/html"
                : "application/octet-stream";
            ex.getResponseHeaders().add("Content-Type", ct);
            ex.sendResponseHeaders(200, body.length);
            try (OutputStream os = ex.getResponseBody()) { os.write(body); }
        }
    }

    static void writeJson(HttpExchange ex, int status, Object body) throws IOException {
        byte[] payload = GSON.toJson(body).getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().add("Content-Type", "application/json");
        ex.sendResponseHeaders(status, payload.length);
        try (OutputStream os = ex.getResponseBody()) { os.write(payload); }
    }

    static class SetupHandler implements HttpHandler {
        public void handle(HttpExchange ex) throws IOException {
            if (!"POST".equals(ex.getRequestMethod())) { ex.sendResponseHeaders(405, -1); return; }
            String body = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            Map<String, String> data = GSON.fromJson(body, new TypeToken<Map<String, String>>(){}.getType());
            String projectId = data.getOrDefault("project_id", "").trim();
            String space = data.getOrDefault("space", "").trim();
            String token = data.getOrDefault("token", "").trim();
            if (projectId.isEmpty() || space.isEmpty() || token.isEmpty()) {
                writeJson(ex, 400, Map.of("ok", false, "error", "All fields required"));
                return;
            }
            try {
                RestClient client = RestClient.builder().project(projectId).token(token).space(space).build();
                Object resp = client.phoneNumbers().list(Map.of("limit", 20));
                NUMBERS = (resp instanceof List<?> list) ? toNumbers(list) : List.of();
                STATE.put("project_id", projectId);
                STATE.put("space", space);
                STATE.put("token", token);
                writeJson(ex, 200, Map.of(
                    "ok", true, "jwt", "", "subscriber_id", "",
                    "numbers", NUMBERS, "agent_path", "/agent"
                ));
            } catch (Exception e) {
                writeJson(ex, 400, Map.of("ok", false, "error", "Credential check failed: " + e.getMessage()));
            }
        }

        @SuppressWarnings("unchecked")
        static List<Map<String, Object>> toNumbers(List<?> list) {
            List<Map<String, Object>> out = new ArrayList<>();
            for (Object o : list) {
                if (o instanceof Map<?, ?> m) {
                    out.add(Map.of(
                        "sid", String.valueOf(m.getOrDefault("sid", "")),
                        "phone_number", String.valueOf(m.getOrDefault("phone_number", ""))
                    ));
                }
            }
            return out;
        }
    }

    static class WireNumberHandler implements HttpHandler {
        public void handle(HttpExchange ex) throws IOException {
            if (!"POST".equals(ex.getRequestMethod())) { ex.sendResponseHeaders(405, -1); return; }
            if (STATE.isEmpty()) { writeJson(ex, 400, Map.of("ok", false, "error", "Run setup first")); return; }
            String body = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            Map<String, String> data = GSON.fromJson(body, new TypeToken<Map<String, String>>(){}.getType());
            String sid = data.getOrDefault("sid", "").trim();
            String publicUrl = data.getOrDefault("public_url", "").trim();
            if (sid.isEmpty() || publicUrl.isEmpty()) {
                writeJson(ex, 400, Map.of("ok", false, "error", "sid + public_url required"));
                return;
            }
            try {
                RestClient client = RestClient.builder()
                    .project(STATE.get("project_id"))
                    .token(STATE.get("token"))
                    .space(STATE.get("space"))
                    .build();
                String voiceUrl = publicUrl.replaceAll("/$", "") + "/agent";
                client.phoneNumbers().update(sid, Map.of("voice_url", voiceUrl, "voice_method", "POST"));
                writeJson(ex, 200, Map.of("ok", true, "voice_url", voiceUrl));
            } catch (Exception e) {
                writeJson(ex, 400, Map.of("ok", false, "error", e.getMessage()));
            }
        }
    }
}
