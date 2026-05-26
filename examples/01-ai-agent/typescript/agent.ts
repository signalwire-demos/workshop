/**
 * Workshop AI Agent — Pillar 1 reference (TypeScript).
 *
 * Mirror of the Python WorkshopAgent. Demonstrates the same 3 ways to give an
 * agent a capability: addSkillByName, defineTool, DataMap.
 */
import { AgentBase, DataMap, FunctionResult } from "@signalwire/sdk";

export class WorkshopAgent extends AgentBase {
  constructor() {
    super({ name: "workshop-agent", route: "/agent" });

    this.addLanguage({
      name: "English",
      code: "en-US",
      voice: "rime.spore",
      speechFillers: ["Um", "Well", "Sure"],
    });

    this.promptAddSection({
      title: "Personality",
      body:
        "You are a friendly demo assistant in a SignalWire workshop. " +
        "Sound warm and natural, keep replies short.",
    });
    this.promptAddSection({
      title: "Greeting",
      body:
        "Greet the caller, say you're the workshop demo agent, " +
        "and ask what they'd like to try.",
    });
    this.promptAddSection({
      title: "Capabilities",
      bullets: [
        "tell_joke — tell a dad joke from icanhazdadjoke",
        "get_weather — current weather for a city",
        "datetime — current date and time anywhere",
        "math — arithmetic, percentages, conversions",
      ],
    });

    // Built-in skills (one-liners)
    void this.addSkillByName("datetime");
    void this.addSkillByName("math");

    // Custom SWAIG function — you write the handler.
    this.defineTool({
      name: "tell_joke",
      description:
        "Tell a fresh dad joke from the icanhazdadjoke API. " +
        "Use whenever the caller asks for a joke or wants entertainment.",
      parameters: { type: "object", properties: {}, required: [] },
      handler: async () => {
        try {
          const r = await fetch("https://icanhazdadjoke.com/", {
            headers: { Accept: "application/json", "User-Agent": "SignalWire-Workshop" },
          });
          const data = (await r.json()) as { joke?: string };
          return new FunctionResult(
            data.joke ?? "I had a joke about UDP, but you might not get it.",
          );
        } catch {
          return new FunctionResult("I had a joke about timeouts, but it never came back.");
        }
      },
    });

    // DataMap — declarative, runs server-side. No handler.
    const weather = new DataMap("get_weather")
      .description(
        "Get the current weather for a city. Use whenever the caller asks " +
          "about weather, temperature, or conditions in any location.",
      )
      .parameter("city", "string", "The city name", true)
      .webhook(
        "GET",
        "https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json",
      )
      .output(
        new FunctionResult(
          "I'm looking up ${args.city}. Coordinates: " +
            "${response.results[0].latitude}, ${response.results[0].longitude}. " +
            "Country: ${response.results[0].country}.",
        ),
      )
      .fallbackOutput(
        new FunctionResult("I couldn't find weather data for ${args.city} right now."),
      );

    this.registerSwaigFunction(weather.toSwaigFunction());
  }
}
