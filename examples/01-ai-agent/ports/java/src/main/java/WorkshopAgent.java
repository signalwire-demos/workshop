import com.signalwire.sdk.agent.AgentBase;
import com.signalwire.sdk.datamap.DataMap;
import com.signalwire.sdk.swaig.FunctionResult;
import com.google.gson.Gson;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Map;

/** Workshop AI Agent — Pillar 1 reference (Java). */
public class WorkshopAgent extends AgentBase {
    private static final Gson GSON = new Gson();
    private static final HttpClient HTTP = HttpClient.newHttpClient();

    public WorkshopAgent() {
        super("workshop-agent", "/agent");

        addLanguage("English", "en-US", "rime.spore", List.of("Um", "Well", "Sure"), null, null, null);

        promptAddSection("Personality",
            "You are a friendly demo assistant in a SignalWire workshop. " +
            "Sound warm and natural, keep replies short.");
        promptAddSection("Greeting",
            "Greet the caller, say you're the workshop demo agent, " +
            "and ask what they'd like to try.");
        promptAddSection("Capabilities", null, List.of(
            "tell_joke — tell a dad joke from icanhazdadjoke",
            "get_weather — current weather for a city",
            "datetime — current date and time anywhere",
            "math — arithmetic, percentages, conversions"
        ));

        addSkill("datetime", null);
        addSkill("math", null);

        defineTool(
            "tell_joke",
            "Tell a fresh dad joke from the icanhazdadjoke API. " +
                "Use whenever the caller asks for a joke or wants entertainment.",
            Map.of("type", "object", "properties", Map.of(), "required", List.of()),
            (args, raw) -> {
                try {
                    HttpRequest req = HttpRequest.newBuilder(URI.create("https://icanhazdadjoke.com/"))
                        .header("Accept", "application/json")
                        .header("User-Agent", "SignalWire-Workshop")
                        .GET().build();
                    HttpResponse<String> resp = HTTP.send(req, HttpResponse.BodyHandlers.ofString());
                    Map<?, ?> payload = GSON.fromJson(resp.body(), Map.class);
                    Object joke = payload.get("joke");
                    return new FunctionResult(joke != null ? joke.toString()
                        : "I had a joke about UDP, but you might not get it.");
                } catch (Exception e) {
                    return new FunctionResult("I had a joke about timeouts, but it never came back.");
                }
            }
        );

        DataMap weather = DataMap.of("get_weather")
            .description("Get the current weather for a city. Use whenever the caller asks " +
                "about weather, temperature, or conditions in any location.")
            .parameter("city", "string", "The city name", true)
            .webhook("GET", "https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json")
            .output(new FunctionResult(
                "I'm looking up ${args.city}. Coordinates: " +
                "${response.results[0].latitude}, ${response.results[0].longitude}. " +
                "Country: ${response.results[0].country}."))
            .fallbackOutput(new FunctionResult(
                "I couldn't find weather data for ${args.city} right now."));

        registerSwaigFunction(weather.toSwaigFunction());
    }
}
