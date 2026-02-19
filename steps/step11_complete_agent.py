#!/usr/bin/env python3
"""
Complete Workshop Agent
-----------------------
A polished AI phone assistant with four capabilities:
  - Dad jokes via API Ninjas (custom define_tool)
  - Weather via WeatherAPI (serverless DataMap)
  - Date/time via built-in skill
  - Math via built-in skill

Run: python complete_agent.py
Test: swaig-test complete_agent.py --dump-swml
"""

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

from signalwire_agents import AgentBase, SwaigFunctionResult
from signalwire_agents.core.data_map import DataMap


class CompleteAgent(AgentBase):
    def __init__(self):
        super().__init__(name="complete-agent")

        self._configure_voice()
        self._configure_params()
        self._configure_prompts()
        self._register_joke_function()
        self._register_weather_datamap()
        self._register_skills()
        self._configure_post_prompt()

    # ------------------------------------------------------------------
    # Voice and speech
    # ------------------------------------------------------------------

    def _configure_voice(self):
        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well", "So"],
            function_fillers=[
                "Let me check on that for you...",
                "One moment while I look that up...",
                "Hang on just a sec...",
            ]
        )

        self.add_hints([
            "Buddy", "weather", "joke", "temperature",
            "forecast", "Fahrenheit", "Celsius",
        ])

    # ------------------------------------------------------------------
    # AI parameters
    # ------------------------------------------------------------------

    def _configure_params(self):
        self.set_params({
            "end_of_speech_timeout": 600,
            "attention_timeout": 15000,
            "attention_timeout_prompt":
                "Are you still there? I can help with weather, "
                "jokes, math, or just chat!",
        })

    # ------------------------------------------------------------------
    # Prompts
    # ------------------------------------------------------------------

    def _configure_prompts(self):
        self.prompt_add_section(
            "Personality",
            "You are Buddy, a cheerful and witty AI phone assistant. "
            "You have a warm, upbeat personality and you genuinely enjoy "
            "helping people. You're a bit of a dad joke enthusiast. "
            "Think of yourself as that friendly neighbor who always "
            "has a joke ready and knows what the weather is like."
        )

        self.prompt_add_section(
            "Voice Style",
            body="Since this is a phone conversation:",
            bullets=[
                "Keep responses to 1-2 sentences when possible",
                "Use conversational language, not formal or robotic",
                "React naturally to what the caller says",
                "Use smooth transitions between topics",
            ]
        )

        self.prompt_add_section(
            "Capabilities",
            body="You can help with:",
            bullets=[
                "Weather: current conditions for any city worldwide",
                "Jokes: endless supply of fresh dad jokes",
                "Date and time: current time in any timezone",
                "Math: calculations, percentages, unit conversions",
                "General chat: friendly conversation on any topic",
            ]
        )

        self.prompt_add_section(
            "Greeting",
            "When the call starts, introduce yourself as Buddy and "
            "briefly mention what you can help with. Keep the greeting "
            "to one or two sentences -- don't list every capability."
        )

    # ------------------------------------------------------------------
    # Dad jokes -- custom function calling API Ninjas
    # ------------------------------------------------------------------

    def _register_joke_function(self):
        self.define_tool(
            name="tell_joke",
            description=(
                "Tell the caller a funny dad joke. Use this whenever "
                "someone asks for a joke, humor, or to be entertained."
            ),
            parameters={"type": "object", "properties": {}},
            handler=self.on_tell_joke,
            fillers={
                "en-US": [
                    "Let me think of a good one...",
                    "Oh, I've got one for you...",
                    "Here comes a good one...",
                ],
            },
        )

    def on_tell_joke(self, args, raw_data):
        api_key = os.getenv("API_NINJAS_KEY", "")
        if not api_key:
            return SwaigFunctionResult(
                "Sorry, my joke book is unavailable right now."
            )

        try:
            resp = requests.get(
                "https://api.api-ninjas.com/v1/dadjokes",
                headers={"X-Api-Key": api_key},
                timeout=5,
            )
            resp.raise_for_status()
            jokes = resp.json()
            if jokes:
                return SwaigFunctionResult(
                    f"Here's a dad joke: {jokes[0]['joke']}"
                )
            return SwaigFunctionResult(
                "I couldn't find a joke this time. Try again!"
            )
        except requests.RequestException:
            return SwaigFunctionResult(
                "My joke service is taking a break. Try again in a moment!"
            )

    # ------------------------------------------------------------------
    # Weather -- DataMap (runs on SignalWire, not our server)
    # ------------------------------------------------------------------

    def _register_weather_datamap(self):
        api_key = os.getenv("WEATHER_API_KEY", "")

        weather_dm = (
            DataMap("get_weather")
            .description(
                "Get the current weather for a city. Use this when "
                "the caller asks about weather, temperature, or conditions."
            )
            .parameter(
                "city", "string",
                "The city to get weather for",
                required=True,
            )
            .webhook(
                "GET",
                "https://api.weatherapi.com/v1/current.json"
                f"?key={api_key}&q=${{enc:args.city}}"
            )
            .output(SwaigFunctionResult(
                "Weather in ${args.city}: "
                "${response.current.condition.text}, "
                "${response.current.temp_f} degrees Fahrenheit, "
                "humidity ${response.current.humidity} percent. "
                "Feels like ${response.current.feelslike_f} degrees."
            ))
            .fallback_output(SwaigFunctionResult(
                "Sorry, I couldn't get the weather for ${args.city}. "
                "Please check the city name and try again."
            ))
        )

        self.register_swaig_function(weather_dm.to_swaig_function())

    # ------------------------------------------------------------------
    # Skills -- built-in, zero-code capabilities
    # ------------------------------------------------------------------

    def _register_skills(self):
        self.add_skill("datetime", {"default_timezone": "America/New_York"})
        self.add_skill("math")

    # ------------------------------------------------------------------
    # Post-prompt -- save call summaries for debugging
    # ------------------------------------------------------------------

    def _configure_post_prompt(self):
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Note what the caller asked about (weather, jokes, time, math, etc.) "
            "and how the interaction went."
        )

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging.

        View saved files at: https://postpromptviewer.signalwire.io/
        """
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")


if __name__ == "__main__":
    agent = CompleteAgent()
    agent.run()
