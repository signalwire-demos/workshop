#!/usr/bin/env python3
"""Agent with a hardcoded joke function."""

import json
import os
import random
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

from signalwire_agents import AgentBase, SwaigFunctionResult

JOKES = [
    "Why do programmers prefer dark mode? Because light attracts bugs.",
    "I told my wife she was drawing her eyebrows too high. She looked surprised.",
    "What do you call a fake noodle? An impasta.",
    "Why don't scientists trust atoms? Because they make up everything.",
    "I'm reading a book about anti-gravity. It's impossible to put down.",
    "What did the ocean say to the beach? Nothing, it just waved.",
    "Why did the scarecrow win an award? He was outstanding in his field.",
    "I used to hate facial hair, but then it grew on me.",
]

class JokeAgent(AgentBase):
    def __init__(self):
        super().__init__(name="joke-agent")

        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well"],
            function_fillers=["Let me think of a good one..."]
        )

        self.prompt_add_section(
            "Role",
            "You are a friendly assistant named Buddy. "
            "You love telling jokes and making people laugh. "
            "Keep your responses short since this is a phone call."
        )

        self.prompt_add_section(
            "Guidelines",
            body="Follow these guidelines:",
            bullets=[
                "When someone asks for a joke, use the tell_joke function",
                "After telling a joke, pause for a reaction before offering another",
                "Be enthusiastic and have fun with it",
            ]
        )

        # Register the joke function
        self.define_tool(
            name="tell_joke",
            description="Tell the caller a funny joke. Use this whenever someone asks for a joke or humor.",
            parameters={"type": "object", "properties": {}},
            handler=self.on_tell_joke,
        )

        # Post-prompt: summarize every call and save to calls/ folder
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Note which jokes were told and how the caller reacted."
        )

    def on_tell_joke(self, args, raw_data):
        joke = random.choice(JOKES)
        return SwaigFunctionResult(f"Here's a joke: {joke}")

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging."""
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")

if __name__ == "__main__":
    agent = JokeAgent()
    agent.run()
