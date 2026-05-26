/**
 * Workshop RELAY realtime — Pillar 3 (TypeScript).
 *
 * Mirror of the Python RELAY example. Backend opens a RelayClient, forwards
 * events over a browser WebSocket, and exposes an outbound dial button.
 */
import express from "express";
import { createServer } from "http";
import { WebSocketServer, WebSocket } from "ws";
import { fileURLToPath } from "url";
import { dirname, join, resolve } from "path";
import { RelayClient, RestClient } from "@signalwire/sdk";

const HERE = dirname(fileURLToPath(import.meta.url));
const SHARED_UI = resolve(HERE, "..", "..", "..", "shared", "ui");

interface Creds { project_id: string; space: string; token: string }
const STATE: {
  creds: Creds | null;
  relay: RelayClient | null;
  subscribers: Set<WebSocket>;
} = { creds: null, relay: null, subscribers: new Set() };

function broadcast(event: Record<string, unknown>) {
  const json = JSON.stringify(event);
  for (const ws of STATE.subscribers) {
    if (ws.readyState === WebSocket.OPEN) ws.send(json);
  }
}

const app = express();
app.use(express.json());
app.use("/shared", express.static(SHARED_UI));

app.get("/", (_req, res) => res.sendFile(join(SHARED_UI, "creds-form.html")));
app.get("/demo.js", (_req, res) =>
  res.type("application/javascript").sendFile(join(HERE, "demo.js")),
);

app.post("/api/setup", async (req, res) => {
  const project_id = String(req.body.project_id ?? "").trim();
  const space = String(req.body.space ?? "").trim();
  const token = String(req.body.token ?? "").trim();
  if (!project_id || !space || !token) {
    return res.status(400).json({ ok: false, error: "All fields required" });
  }
  try {
    await new RestClient({ project: project_id, token, host: space }).phoneNumbers.list({ limit: 1 });
  } catch (e) {
    return res.status(400).json({ ok: false, error: `Credential check failed: ${(e as Error).message}` });
  }

  // Tear down any existing client
  if (STATE.relay) {
    try { await STATE.relay.disconnect?.(); } catch {}
    STATE.relay = null;
  }

  const relay = new RelayClient({ project: project_id, token, host: space, contexts: ["workshop"] });
  relay.onCall(async (call) => {
    broadcast({ kind: "call", state: "incoming", call_id: call.callId, from: (call as any).from_number, to: (call as any).to_number });
    try {
      await call.answer();
      broadcast({ kind: "call", state: "answered", call_id: call.callId });
    } catch (e) {
      broadcast({ kind: "error", message: `answer failed: ${(e as Error).message}` });
    }
  });

  // Connect in background
  (async () => {
    try {
      await relay.connect();
      broadcast({ kind: "system", message: "RELAY connected" });
    } catch (e) {
      broadcast({ kind: "error", message: `RELAY connect failed: ${(e as Error).message}` });
    }
  })();

  STATE.creds = { project_id, space, token };
  STATE.relay = relay;
  res.json({ ok: true, jwt: "session-validated", subscriber_id: "n/a" });
});

app.post("/api/dial", async (req, res) => {
  if (!STATE.relay) return res.status(400).json({ ok: false, error: "Run setup first" });
  const to = String(req.body.to ?? "").trim();
  const from = String(req.body.from ?? "").trim();
  if (!to || !from) return res.status(400).json({ ok: false, error: "from + to required" });
  try {
    const devices = [[{ type: "phone", from, to, timeout: 30 }]];
    const call = await STATE.relay.dial(devices, { dialTimeout: 60 });
    res.json({ ok: true, call_id: call.callId });
  } catch (e) {
    res.status(400).json({ ok: false, error: (e as Error).message });
  }
});

const PORT = Number(process.env.PORT ?? 8002);
const server = createServer(app);
const wss = new WebSocketServer({ server, path: "/ws/events" });

wss.on("connection", (ws) => {
  STATE.subscribers.add(ws);
  if (!STATE.relay) {
    ws.send(JSON.stringify({ kind: "error", message: "Run setup first" }));
  } else {
    ws.send(JSON.stringify({ kind: "system", message: "ws connected" }));
  }
  ws.on("close", () => STATE.subscribers.delete(ws));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`RELAY realtime listening on http://0.0.0.0:${PORT}`);
});
