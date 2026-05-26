/**
 * Workshop AI Agent app — Pillar 1 (TypeScript).
 *
 * Serves shared UI + /api/setup + the agent at /agent.
 */
import express from "express";
import { fileURLToPath } from "url";
import { dirname, join, resolve } from "path";
import { AgentServer, RestClient } from "@signalwire/sdk";
import { WorkshopAgent } from "./agent.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const SHARED_UI = resolve(HERE, "..", "..", "..", "shared", "ui");

interface Creds { project_id: string; space: string; token: string }
interface NumberInfo { sid: string | null; phone_number: string | null }

const STATE: {
  creds: Creds | null;
  numbers: NumberInfo[];
} = { creds: null, numbers: [] };

const PORT = Number(process.env.PORT ?? 8000);

const server = new AgentServer({ host: "0.0.0.0", port: PORT });
server.register(new WorkshopAgent(), "/agent");

const app = (server as unknown as { app: express.Express }).app;

app.use("/shared", express.static(SHARED_UI));

app.get("/", (_req, res) => {
  res.sendFile(join(SHARED_UI, "creds-form.html"));
});

app.get("/demo.js", (_req, res) => {
  res.type("application/javascript").sendFile(join(HERE, "demo.js"));
});

app.post("/api/setup", express.json(), async (req, res) => {
  const project_id = String(req.body.project_id ?? "").trim();
  const space = String(req.body.space ?? "").trim();
  const token = String(req.body.token ?? "").trim();

  if (!project_id || !space || !token) {
    return res.status(400).json({ ok: false, error: "All fields are required" });
  }

  let numbersResp: unknown;
  try {
    const client = new RestClient({ project: project_id, token, host: space });
    numbersResp = await client.phoneNumbers.list({ limit: 20 });
  } catch (e) {
    return res.status(400).json({ ok: false, error: `Credential check failed: ${(e as Error).message}` });
  }

  const numbers: NumberInfo[] = Array.isArray(numbersResp)
    ? (numbersResp as Array<Record<string, unknown>>).map((n) => ({
        sid: (n.sid as string) ?? null,
        phone_number: (n.phone_number as string) ?? null,
      }))
    : [];

  let jwt = "";
  let subscriber_id = "";
  try {
    const client = new RestClient({ project: project_id, token, host: space });
    const tokResp = await client.fabric.createSubscriberToken({
      reference: "workshop-attendee",
      permissions: ["fabric.subscriber.read"],
    });
    if (tokResp && typeof tokResp === "object") {
      const r = tokResp as Record<string, string>;
      jwt = r.token ?? "";
      subscriber_id = r.subscriber_id ?? "";
    }
  } catch {
    // Subscriber tokens require Fabric on the account; non-blocking.
  }

  STATE.creds = { project_id, space, token };
  STATE.numbers = numbers;

  res.json({ ok: true, jwt, subscriber_id, numbers, agent_path: "/agent" });
});

app.post("/api/wire-number", express.json(), async (req, res) => {
  if (!STATE.creds) return res.status(400).json({ ok: false, error: "Run /api/setup first" });
  const sid = String(req.body.sid ?? "").trim();
  const public_url = String(req.body.public_url ?? "").trim();
  if (!sid || !public_url) return res.status(400).json({ ok: false, error: "sid + public_url required" });

  try {
    const client = new RestClient({
      project: STATE.creds.project_id,
      token: STATE.creds.token,
      host: STATE.creds.space,
    });
    const voice_url = public_url.replace(/\/$/, "") + "/agent";
    await client.phoneNumbers(sid).update({ voice_url, voice_method: "POST" });
    res.json({ ok: true, voice_url });
  } catch (e) {
    res.status(400).json({ ok: false, error: `Update failed: ${(e as Error).message}` });
  }
});

server.run();
