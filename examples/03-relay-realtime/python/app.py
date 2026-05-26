"""
Workshop RELAY realtime — Pillar 3 (Python).

Opens a SignalWire RELAY WebSocket connection in the background, listens for
incoming-call events, and forwards them over a browser WebSocket so the UI
can render a live event feed. UI also has a button that triggers an outbound
dial via client.dial(...).
"""

import asyncio
import json
import os
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import uvicorn

from signalwire.rest import RestClient
from signalwire.relay.client import RelayClient


HERE = Path(__file__).resolve().parent
SHARED_UI = HERE.parents[2] / "shared" / "ui"

STATE: dict[str, Any] = {
    "creds": None,
    "relay_client": None,
    "relay_task": None,
    "event_queue": None,
}


async def _relay_runner(client: RelayClient, queue: asyncio.Queue):
    """Background task — connect to RELAY and pump events into queue."""

    @client.on_call
    async def handle(call):
        await queue.put({
            "kind": "call",
            "state": "incoming",
            "call_id": call.call_id,
            "from": getattr(call, "from_number", None),
            "to": getattr(call, "to_number", None),
        })
        try:
            await call.answer()
            await queue.put({"kind": "call", "state": "answered", "call_id": call.call_id})
        except Exception as e:
            await queue.put({"kind": "error", "message": f"answer failed: {e}"})

    try:
        await client.connect()
        await queue.put({"kind": "system", "message": "RELAY connected"})
        # Block until cancelled. RelayClient handles event dispatch internally.
        while True:
            await asyncio.sleep(3600)
    except asyncio.CancelledError:
        await queue.put({"kind": "system", "message": "RELAY disconnected"})
        raise
    except Exception as e:
        await queue.put({"kind": "error", "message": f"RELAY error: {e}"})


def make_app() -> FastAPI:
    app = FastAPI(title="SignalWire Workshop — RELAY Realtime", redirect_slashes=False)

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
            RestClient(project=project_id, token=token, host=space).phone_numbers.list(limit=1)
        except Exception as e:
            return JSONResponse({"ok": False, "error": f"Credential check failed: {e}"}, status_code=400)

        # Tear down any existing relay task
        if STATE.get("relay_task"):
            STATE["relay_task"].cancel()
            STATE["relay_task"] = None

        # Start a fresh relay task in the background.
        queue: asyncio.Queue = asyncio.Queue(maxsize=256)
        relay = RelayClient(project=project_id, token=token, host=space, contexts=["workshop"])
        task = asyncio.create_task(_relay_runner(relay, queue))

        STATE["creds"] = {"project_id": project_id, "space": space, "token": token}
        STATE["relay_client"] = relay
        STATE["relay_task"] = task
        STATE["event_queue"] = queue

        return {"ok": True, "jwt": "session-validated", "subscriber_id": "n/a"}

    @app.websocket("/ws/events")
    async def ws_events(ws: WebSocket):
        await ws.accept()
        queue: asyncio.Queue = STATE.get("event_queue")
        if not queue:
            await ws.send_json({"kind": "error", "message": "Run setup first"})
            await ws.close()
            return
        try:
            while True:
                event = await queue.get()
                await ws.send_json(event)
        except WebSocketDisconnect:
            pass
        except Exception as e:
            try:
                await ws.send_json({"kind": "error", "message": str(e)})
            except Exception:
                pass

    @app.post("/api/dial")
    async def api_dial(req: Request):
        client: RelayClient = STATE.get("relay_client")
        if not client:
            return JSONResponse({"ok": False, "error": "Run setup first"}, status_code=400)
        data = await req.json()
        to = (data.get("to") or "").strip()
        from_ = (data.get("from") or "").strip()
        if not (to and from_):
            return JSONResponse({"ok": False, "error": "from + to required"}, status_code=400)
        try:
            devices = [[{"type": "phone", "from": from_, "to": to, "timeout": 30}]]
            call = await client.dial(devices, dial_timeout=60.0)
            return {"ok": True, "call_id": call.call_id}
        except Exception as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)

    return app


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8002"))
    uvicorn.run(make_app(), host="0.0.0.0", port=port)
