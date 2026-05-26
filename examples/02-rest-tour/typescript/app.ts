/**
 * Workshop REST tour — Pillar 2 (TypeScript).
 *
 * Mirror of the Python REST tour. 4 demo buttons calling the TS RestClient.
 */
import express from "express";
import { fileURLToPath } from "url";
import { dirname, join, resolve } from "path";
import { RestClient } from "@signalwire/sdk";

const HERE = dirname(fileURLToPath(import.meta.url));
const SHARED_UI = resolve(HERE, "..", "..", "..", "shared", "ui");

interface Creds { project_id: string; space: string; token: string }
const STATE: { creds: Creds | null } = { creds: null };

const app = express();
app.use(express.json());
app.use("/shared", express.static(SHARED_UI));

app.get("/", (_req, res) => res.sendFile(join(SHARED_UI, "creds-form.html")));
app.get("/demo.js", (_req, res) =>
  res.type("application/javascript").sendFile(join(HERE, "demo.js")),
);

function client(): RestClient {
  const c = STATE.creds!;
  return new RestClient({ project: c.project_id, token: c.token, host: c.space });
}

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
  STATE.creds = { project_id, space, token };
  res.json({ ok: true, jwt: "session-validated", subscriber_id: "n/a" });
});

app.get("/api/list-numbers", async (_req, res) => {
  if (!STATE.creds) return res.status(400).json({ ok: false, error: "Run setup first" });
  try {
    const response = await client().phoneNumbers.list({ limit: 20 });
    res.json({ ok: true, sdk_call: "client.phoneNumbers.list({ limit: 20 })", response });
  } catch (e) {
    res.status(400).json({ ok: false, error: (e as Error).message });
  }
});

app.post("/api/send-sms", async (req, res) => {
  if (!STATE.creds) return res.status(400).json({ ok: false, error: "Run setup first" });
  const from = String(req.body.from ?? "").trim();
  const to = String(req.body.to ?? "").trim();
  const body = String(req.body.body ?? "Hello from the SignalWire workshop!").trim();
  if (!from || !to) return res.status(400).json({ ok: false, error: "from + to required" });
  try {
    const response = await client().compat.messages.create({ from, to, body });
    res.json({
      ok: true,
      sdk_call: `client.compat.messages.create({ from: "${from}", to: "${to}", body: ... })`,
      response,
    });
  } catch (e) {
    res.status(400).json({ ok: false, error: (e as Error).message });
  }
});

app.get("/api/recent-calls", async (_req, res) => {
  if (!STATE.creds) return res.status(400).json({ ok: false, error: "Run setup first" });
  try {
    const response = await client().compat.calls.list({ pageSize: 10 });
    res.json({ ok: true, sdk_call: "client.compat.calls.list({ pageSize: 10 })", response });
  } catch (e) {
    res.status(400).json({ ok: false, error: (e as Error).message });
  }
});

app.post("/api/wire-number", async (req, res) => {
  if (!STATE.creds) return res.status(400).json({ ok: false, error: "Run setup first" });
  const sid = String(req.body.sid ?? "").trim();
  const voice_url = String(req.body.voice_url ?? "").trim();
  if (!sid || !voice_url) return res.status(400).json({ ok: false, error: "sid + voice_url required" });
  try {
    const response = await client().phoneNumbers(sid).update({ voice_url, voice_method: "POST" });
    res.json({
      ok: true,
      sdk_call: `client.phoneNumbers("${sid}").update({ voice_url: "${voice_url}" })`,
      response,
    });
  } catch (e) {
    res.status(400).json({ ok: false, error: (e as Error).message });
  }
});

const PORT = Number(process.env.PORT ?? 8001);
app.listen(PORT, "0.0.0.0", () => {
  console.log(`REST tour listening on http://0.0.0.0:${PORT}`);
});
