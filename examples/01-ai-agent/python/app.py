"""
Workshop AI Agent app — Pillar 1 (Python).

Serves three things at port 8000:
  - /                 → shared/ui/creds-form.html
  - /shared/*         → shared UI assets (CSS, JS)
  - /demo.js          → pillar-specific demo view
  - /api/setup        → validate creds, mint subscriber token, return number list
  - /api/wire-number  → point a chosen number's voice webhook at this agent
  - /agent/*          → the SignalWire agent (SWML + SWAIG endpoints)
"""

import os
from pathlib import Path
from urllib.parse import quote, urlparse, urlunparse

from fastapi import Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from signalwire import AgentServer
from signalwire.rest import RestClient

from agent import WorkshopAgent


HERE = Path(__file__).resolve().parent
SHARED_UI = HERE.parents[2] / "shared" / "ui"

# In-process credential store. Workshop-only — one attendee per process.
STATE = {"creds": None, "numbers": [], "wired_number": None}


def make_server() -> AgentServer:
    server = AgentServer(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
    agent = WorkshopAgent()
    server.register(agent, route="/agent")
    # Capture the agent's basic-auth creds so /api/wire-number can embed
    # them in the voice webhook URL. SignalWire's voice service does HTTP
    # Basic against the agent endpoint — without these in the URL, every
    # inbound call gets 401.
    STATE["agent_basic_auth"] = agent.get_basic_auth_credentials()

    app = server.app

    app.mount("/shared", StaticFiles(directory=str(SHARED_UI)), name="shared")

    @app.get("/")
    def root():
        return FileResponse(SHARED_UI / "creds-form.html")

    @app.get("/demo.js")
    def demo_js():
        return FileResponse(HERE / "demo.js", media_type="application/javascript")

    @app.post("/api/setup")
    async def api_setup(req: Request):
        data = await req.json()
        project_id = (data.get("project_id") or "").strip()
        space = (data.get("space") or "").strip()
        token = (data.get("token") or "").strip()
        if not (project_id and space and token):
            return JSONResponse({"ok": False, "error": "All fields are required"}, status_code=400)

        try:
            client = RestClient(project=project_id, token=token, host=space)
            numbers_resp = client.phone_numbers.list(limit=20)
        except Exception as e:
            return JSONResponse({"ok": False, "error": f"Credential check failed: {e}"}, status_code=400)

        numbers = []
        try:
            for n in (numbers_resp or []):
                numbers.append({
                    "sid": n.get("sid") if isinstance(n, dict) else None,
                    "phone_number": n.get("phone_number") if isinstance(n, dict) else None,
                })
        except Exception:
            numbers = []

        # Try to mint a subscriber token for client-side use (RELAY pillar needs this).
        jwt = ""
        subscriber_id = ""
        try:
            tok_resp = client.fabric.create_subscriber_token(
                reference="workshop-attendee",
                permissions=["fabric.subscriber.read"],
            )
            if isinstance(tok_resp, dict):
                jwt = tok_resp.get("token", "") or ""
                subscriber_id = tok_resp.get("subscriber_id", "") or ""
        except Exception:
            # Subscriber tokens require Fabric on the account; non-blocking for Pillar 1.
            pass

        STATE["creds"] = {"project_id": project_id, "space": space, "token": token}
        STATE["numbers"] = numbers

        return {
            "ok": True,
            "jwt": jwt,
            "subscriber_id": subscriber_id,
            "numbers": numbers,
            "agent_path": "/agent",
        }

    @app.post("/api/wire-number")
    async def api_wire_number(req: Request):
        data = await req.json()
        sid = (data.get("sid") or "").strip()
        public_url = (data.get("public_url") or "").strip()
        if not STATE["creds"]:
            return JSONResponse({"ok": False, "error": "Run /api/setup first"}, status_code=400)
        if not (sid and public_url):
            return JSONResponse({"ok": False, "error": "sid + public_url required"}, status_code=400)

        creds = STATE["creds"]
        try:
            client = RestClient(project=creds["project_id"], token=creds["token"], host=creds["space"])
            # Embed agent's basic-auth creds in the voice URL so SignalWire's
            # voice service can authenticate when calling the webhook.
            user, pw = STATE["agent_basic_auth"]
            parsed = urlparse(public_url.rstrip("/") + "/agent")
            netloc_with_auth = f"{quote(user, safe='')}:{quote(pw, safe='')}@{parsed.netloc}"
            voice_url = urlunparse(parsed._replace(netloc=netloc_with_auth))
            client.phone_numbers(sid).update(voice_url=voice_url, voice_method="POST")
            STATE["wired_number"] = {"sid": sid, "voice_url": voice_url}
            # Don't leak the password back to the browser — return the
            # un-credentialed display URL.
            display_url = public_url.rstrip("/") + "/agent"
            return {"ok": True, "voice_url": display_url}
        except Exception as e:
            return JSONResponse({"ok": False, "error": f"Update failed: {e}"}, status_code=400)

    return server


if __name__ == "__main__":
    make_server().run()
