"""
Workshop REST tour — Pillar 2 (Python).

Demonstrates the REST SDK end-to-end via 4 demo buttons:
  - GET /api/list-numbers     → client.phone_numbers.list()
  - POST /api/send-sms        → client.compat.messages.create(...)
  - GET /api/recent-calls     → client.compat.calls.list(limit=10)
  - POST /api/wire-number     → client.phone_numbers(sid).update(voice_url=...)
"""

import os
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import uvicorn

from signalwire.rest import RestClient


HERE = Path(__file__).resolve().parent
SHARED_UI = HERE.parents[2] / "shared" / "ui"

STATE = {"creds": None}


def make_app() -> FastAPI:
    app = FastAPI(title="SignalWire Workshop — REST Tour", redirect_slashes=False)

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
            return JSONResponse({"ok": False, "error": "All fields required"}, status_code=400)
        try:
            client = RestClient(project=project_id, token=token, host=space)
            client.phone_numbers.list(limit=1)  # validate
        except Exception as e:
            return JSONResponse({"ok": False, "error": f"Credential check failed: {e}"}, status_code=400)
        STATE["creds"] = {"project_id": project_id, "space": space, "token": token}
        return {"ok": True, "jwt": "session-validated", "subscriber_id": "n/a"}

    def _client() -> RestClient:
        creds = STATE.get("creds") or {}
        return RestClient(project=creds["project_id"], token=creds["token"], host=creds["space"])

    @app.get("/api/list-numbers")
    def list_numbers():
        if not STATE["creds"]:
            return JSONResponse({"ok": False, "error": "Run setup first"}, status_code=400)
        try:
            numbers = _client().phone_numbers.list(limit=20)
            return {
                "ok": True,
                "sdk_call": "client.phone_numbers.list(limit=20)",
                "response": numbers,
            }
        except Exception as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)

    @app.post("/api/send-sms")
    async def send_sms(req: Request):
        if not STATE["creds"]:
            return JSONResponse({"ok": False, "error": "Run setup first"}, status_code=400)
        data = await req.json()
        from_ = (data.get("from") or "").strip()
        to = (data.get("to") or "").strip()
        body = (data.get("body") or "Hello from the SignalWire workshop!").strip()
        if not (from_ and to):
            return JSONResponse({"ok": False, "error": "from + to required"}, status_code=400)
        try:
            resp = _client().compat.messages.create(**{"from": from_, "to": to, "body": body})
            return {
                "ok": True,
                "sdk_call": f"client.compat.messages.create(from_={from_!r}, to={to!r}, body=...)",
                "response": resp,
            }
        except Exception as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)

    @app.get("/api/recent-calls")
    def recent_calls():
        if not STATE["creds"]:
            return JSONResponse({"ok": False, "error": "Run setup first"}, status_code=400)
        try:
            calls = _client().compat.calls.list(page_size=10)
            return {
                "ok": True,
                "sdk_call": "client.compat.calls.list(page_size=10)",
                "response": calls,
            }
        except Exception as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)

    @app.post("/api/wire-number")
    async def wire_number(req: Request):
        if not STATE["creds"]:
            return JSONResponse({"ok": False, "error": "Run setup first"}, status_code=400)
        data = await req.json()
        sid = (data.get("sid") or "").strip()
        voice_url = (data.get("voice_url") or "").strip()
        if not (sid and voice_url):
            return JSONResponse({"ok": False, "error": "sid + voice_url required"}, status_code=400)
        try:
            resp = _client().phone_numbers(sid).update(voice_url=voice_url, voice_method="POST")
            return {
                "ok": True,
                "sdk_call": f"client.phone_numbers({sid!r}).update(voice_url={voice_url!r})",
                "response": resp,
            }
        except Exception as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)

    return app


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8001"))
    uvicorn.run(make_app(), host="0.0.0.0", port=port)
