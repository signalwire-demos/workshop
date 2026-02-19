#!/usr/bin/env python3
"""My first AI phone agent -- Hello World edition."""

import json
import os
from datetime import datetime
import requests
from dotenv import load_dotenv
load_dotenv()

def check_ngrok():
    """Auto-detect ngrok tunnel and set SWML_PROXY_URL_BASE."""
    try:
        resp = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=1)
        tunnels = resp.json().get("tunnels", [])
        for t in tunnels:
            if t.get("proto") == "https":
                url = t["public_url"]
                os.environ["SWML_PROXY_URL_BASE"] = url
                print(f"ngrok detected: {url}")
                return url
    except Exception:
        pass
    current = os.getenv("SWML_PROXY_URL_BASE", "")
    if current:
        print(f"Using SWML_PROXY_URL_BASE from .env: {current}")
    else:
        print("No ngrok tunnel detected and SWML_PROXY_URL_BASE not set")
    return current

check_ngrok()

from signalwire_agents import AgentBase

class HelloAgent(AgentBase):
    def __init__(self):
        super().__init__(name="hello-agent")

        # Set up the voice
        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well"]
        )

        # Tell the AI who it is
        self.prompt_add_section(
            "Role",
            "You are a friendly assistant named Buddy. "
            "You greet callers warmly, ask how their day is going, "
            "and have a brief pleasant conversation. "
            "Keep your responses short since this is a phone call."
        )

        # Post-prompt: summarize every call and save to calls/ folder
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Include what the caller wanted and how the conversation went."
        )

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging."""
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")

if __name__ == "__main__":
    agent = HelloAgent()
    agent.run()
