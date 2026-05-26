// Workshop AI Agent — Pillar 1 (C++ CLI).
//
// CLI-only: builds the agent, prints the webhook URL, and runs the
// blocking HTTP server. Use the SignalWire dashboard or the Pillar 2
// REST tour to wire a phone number to /agent.

#include <signalwire/agent/agent_base.hpp>
#include <signalwire/datamap/datamap.hpp>
#include <signalwire/swaig/function_result.hpp>
#include <curl/curl.h>

#include <iostream>
#include <sstream>
#include <string>

using namespace signalwire;

static size_t curl_write_cb(void* contents, size_t size, size_t nmemb, std::string* out) {
    out->append(static_cast<char*>(contents), size * nmemb);
    return size * nmemb;
}

static std::string fetch_joke() {
    CURL* curl = curl_easy_init();
    if (!curl) return "I had a joke about timeouts, but it never came back.";
    std::string body;
    struct curl_slist* headers = nullptr;
    headers = curl_slist_append(headers, "Accept: application/json");
    headers = curl_slist_append(headers, "User-Agent: SignalWire-Workshop");
    curl_easy_setopt(curl, CURLOPT_URL, "https://icanhazdadjoke.com/");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &body);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 5L);
    auto rc = curl_easy_perform(curl);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    if (rc != CURLE_OK) return "I had a joke about UDP, but you might not get it.";
    // Crude JSON extraction (no JSON dep here)
    auto pos = body.find("\"joke\"");
    if (pos == std::string::npos) return "I had a joke about UDP, but you might not get it.";
    auto colon = body.find(':', pos);
    auto open = body.find('"', colon);
    auto close = body.find('"', open + 1);
    if (open == std::string::npos || close == std::string::npos)
        return "I had a joke about UDP, but you might not get it.";
    return body.substr(open + 1, close - open - 1);
}

int main(int argc, char** argv) {
    int port = (argc > 1) ? std::atoi(argv[1]) : 8000;

    agent::AgentBase agent("workshop-agent", "/agent");

    agent.add_language({"English", "en-US", "rime.spore"});

    agent.prompt_add_section("Personality",
        "You are a friendly demo assistant in a SignalWire workshop. "
        "Sound warm and natural, keep replies short.");
    agent.prompt_add_section("Greeting",
        "Greet the caller, say you're the workshop demo agent, "
        "and ask what they'd like to try.");
    agent.prompt_add_section("Capabilities", "", {
        "tell_joke — tell a dad joke from icanhazdadjoke",
        "get_weather — current weather for a city",
        "datetime — current date and time anywhere",
        "math — arithmetic, percentages, conversions",
    });

    agent.add_skill("datetime");
    agent.add_skill("math");

    agent.define_tool(
        "tell_joke",
        "Tell a fresh dad joke from the icanhazdadjoke API.",
        {{"type", "object"}, {"properties", {}}, {"required", {}}},
        [](auto /*args*/, auto /*raw*/) {
            return swaig::FunctionResult(fetch_joke());
        });

    auto weather = datamap::DataMap("get_weather")
        .description("Get the current weather for a city.")
        .parameter("city", "string", "The city name", true)
        .webhook("GET",
            "https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json")
        .output(swaig::FunctionResult(
            "I'm looking up ${args.city}. Coordinates: "
            "${response.results[0].latitude}, ${response.results[0].longitude}. "
            "Country: ${response.results[0].country}."))
        .fallback_output(swaig::FunctionResult(
            "I couldn't find weather data for ${args.city} right now."));

    agent.register_swaig_function(weather.to_swaig_function());

    std::cout << "Agent listening on http://0.0.0.0:" << port << "/agent\n";
    std::cout << "Wire a SignalWire phone number's voice webhook to this URL.\n";
    agent.run(port);
    return 0;
}
