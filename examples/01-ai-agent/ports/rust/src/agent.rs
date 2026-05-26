//! Workshop AI Agent — Rust reference for Pillar 1.

use signalwire::agent::agent_base::AgentBase;
use signalwire::datamap::datamap::DataMap;
use signalwire::swaig::function_result::FunctionResult;
use serde_json::json;

pub fn build_agent() -> AgentBase {
    let mut a = AgentBase::new("workshop-agent", "/agent");

    a.add_language(json!({
        "name": "English",
        "code": "en-US",
        "voice": "rime.spore",
        "speech_fillers": ["Um", "Well", "Sure"],
    }));

    a.prompt_add_section(
        "Personality",
        "You are a friendly demo assistant in a SignalWire workshop. \
         Sound warm and natural, keep replies short.",
        None,
    );
    a.prompt_add_section(
        "Greeting",
        "Greet the caller, say you're the workshop demo agent, \
         and ask what they'd like to try.",
        None,
    );
    a.prompt_add_section(
        "Capabilities",
        "",
        Some(vec![
            "tell_joke — tell a dad joke from icanhazdadjoke",
            "get_weather — current weather for a city",
            "datetime — current date and time anywhere",
            "math — arithmetic, percentages, conversions",
        ]),
    );

    a.add_skill("datetime", json!({}));
    a.add_skill("math", json!({}));

    a.define_tool(
        "tell_joke",
        "Tell a fresh dad joke from the icanhazdadjoke API. \
         Use whenever the caller asks for a joke or wants entertainment.",
        json!({"type": "object", "properties": {}, "required": []}),
        |_args, _raw| {
            let client = reqwest::blocking::Client::new();
            let res = client
                .get("https://icanhazdadjoke.com/")
                .header("Accept", "application/json")
                .header("User-Agent", "SignalWire-Workshop")
                .send();
            let joke = match res.and_then(|r| r.json::<serde_json::Value>()) {
                Ok(v) => v["joke"].as_str().unwrap_or(
                    "I had a joke about UDP, but you might not get it."
                ).to_string(),
                Err(_) => "I had a joke about timeouts, but it never came back.".to_string(),
            };
            FunctionResult::new(&joke)
        },
        false,
    );

    let weather = DataMap::new("get_weather")
        .description(
            "Get the current weather for a city. Use whenever the caller asks \
             about weather, temperature, or conditions in any location."
        )
        .parameter("city", "string", "The city name", true, &[])
        .webhook(
            "GET",
            "https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json",
            None, "", false, &[],
        )
        .output(FunctionResult::new(
            "I'm looking up ${args.city}. Coordinates: \
             ${response.results[0].latitude}, ${response.results[0].longitude}. \
             Country: ${response.results[0].country}."
        ))
        .fallback_output(FunctionResult::new(
            "I couldn't find weather data for ${args.city} right now."
        ));

    a.register_swaig_function(weather.to_swaig_function());
    a
}
