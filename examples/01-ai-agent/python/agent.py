"""
Workshop AI Agent — Pillar 1 reference (Python).

Demonstrates the three ways to give a SignalWire agent a capability:
  1. add_skill()              — built-in capabilities, one line
  2. define_tool()            — custom SWAIG function, your handler
  3. DataMap                  — declarative API call, runs server-side
"""

import os
import requests

from signalwire import AgentBase, DataMap
from signalwire.core.function_result import FunctionResult


class WorkshopAgent(AgentBase):
    def __init__(self):
        super().__init__(name="workshop-agent", route="/agent")

        self._configure_voice_and_prompts()
        self._add_built_in_skills()
        self._add_custom_joke_function()
        self._add_weather_datamap()

    def _configure_voice_and_prompts(self):
        self.add_language("English", "en-US", "rime.spore",
                          speech_fillers=["Um", "Well", "Sure"])

        self.prompt_add_section(
            "Personality",
            body="You are a friendly demo assistant in a SignalWire workshop. "
                 "Sound warm and natural, keep replies short."
        )
        self.prompt_add_section(
            "Greeting",
            body="Greet the caller, say you're the workshop demo agent, "
                 "and ask what they'd like to try."
        )
        self.prompt_add_section(
            "Capabilities",
            bullets=[
                "tell_joke — tell a dad joke from icanhazdadjoke",
                "get_weather — current weather for a city",
                "datetime — current date and time anywhere",
                "math — arithmetic, percentages, conversions",
            ],
        )

    def _add_built_in_skills(self):
        # One-liner built-ins. Server-side, zero handler code.
        self.add_skill("datetime")
        self.add_skill("math")

    def _add_custom_joke_function(self):
        # Pillar 1 / "Method 2": you write the handler.
        def tell_joke(args, raw_data):
            try:
                r = requests.get(
                    "https://icanhazdadjoke.com/",
                    headers={"Accept": "application/json", "User-Agent": "SignalWire-Workshop"},
                    timeout=5,
                )
                joke = r.json().get("joke", "I had a joke about UDP, but you might not get it.")
            except Exception:
                joke = "I had a joke about timeouts, but it never came back."
            return FunctionResult(joke)

        self.define_tool(
            name="tell_joke",
            description=(
                "Tell a fresh dad joke from the icanhazdadjoke API. "
                "Use this whenever the caller asks for a joke, asks you "
                "to be funny, or wants entertainment."
            ),
            parameters={
                "type": "object",
                "properties": {},
                "required": [],
            },
            handler=tell_joke,
        )

    def _add_weather_datamap(self):
        # Pillar 1 / "Method 3": DataMap — no handler, server-side serverless.
        # Uses Open-Meteo (no API key required).
        weather = (
            DataMap("get_weather")
            .description(
                "Get the current weather for a city. Use this whenever the "
                "caller asks about weather, temperature, or conditions in "
                "any location."
            )
            .parameter("city", "string", "The city name", required=True)
            .webhook(
                "GET",
                "https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json",
            )
            .output(FunctionResult(
                "I'm looking up ${args.city} now. Coordinates: "
                "${response.results[0].latitude}, ${response.results[0].longitude}. "
                "Country: ${response.results[0].country}."
            ))
            .fallback_output(FunctionResult(
                "I couldn't find weather data for ${args.city} right now."
            ))
        )
        self.register_swaig_function(weather.to_swaig_function())
