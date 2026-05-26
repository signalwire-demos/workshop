// Workshop AI Agent — Pillar 1 reference (Go).
//
// Mirror of the Python WorkshopAgent. Same 3 ways to give an agent a
// capability: AddSkill, DefineTool, DataMap.

package main

import (
	"encoding/json"
	"net/http"

	"github.com/signalwire/signalwire-go/pkg/agent"
	"github.com/signalwire/signalwire-go/pkg/datamap"
	"github.com/signalwire/signalwire-go/pkg/swaig"

	_ "github.com/signalwire/signalwire-go/pkg/skills/builtin"
)

func newWorkshopAgent() *agent.AgentBase {
	a := agent.NewAgentBase(
		agent.WithName("workshop-agent"),
		agent.WithRoute("/agent"),
	)

	a.AddLanguage(map[string]any{
		"name":           "English",
		"code":           "en-US",
		"voice":          "rime.spore",
		"speech_fillers": []string{"Um", "Well", "Sure"},
	})

	a.PromptAddSection(
		"Personality",
		"You are a friendly demo assistant in a SignalWire workshop. "+
			"Sound warm and natural, keep replies short.",
		nil,
	)
	a.PromptAddSection(
		"Greeting",
		"Greet the caller, say you're the workshop demo agent, "+
			"and ask what they'd like to try.",
		nil,
	)
	a.PromptAddSection(
		"Capabilities",
		"",
		[]string{
			"tell_joke — tell a dad joke from icanhazdadjoke",
			"get_weather — current weather for a city",
			"datetime — current date and time anywhere",
			"math — arithmetic, percentages, conversions",
		},
	)

	a.AddSkill("datetime", nil)
	a.AddSkill("math", nil)

	a.DefineTool(agent.ToolDefinition{
		Name: "tell_joke",
		Description: "Tell a fresh dad joke from the icanhazdadjoke API. " +
			"Use whenever the caller asks for a joke or wants entertainment.",
		Parameters: map[string]any{
			"type":       "object",
			"properties": map[string]any{},
			"required":   []string{},
		},
		Handler: func(args map[string]any, raw *http.Request) *swaig.FunctionResult {
			resp, err := http.Get("https://icanhazdadjoke.com/")
			if err != nil {
				return swaig.NewFunctionResult("I had a joke about timeouts, but it never came back.")
			}
			defer resp.Body.Close()
			var payload struct{ Joke string `json:"joke"` }
			if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil || payload.Joke == "" {
				return swaig.NewFunctionResult("I had a joke about UDP, but you might not get it.")
			}
			return swaig.NewFunctionResult(payload.Joke)
		},
	})

	weather := datamap.NewDataMap("get_weather").
		Description("Get the current weather for a city. Use whenever the caller asks about weather, "+
			"temperature, or conditions in any location.").
		Parameter("city", "string", "The city name", true, nil).
		Webhook("GET",
			"https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json",
			nil, "", false, nil).
		Output(swaig.NewFunctionResult(
			"I'm looking up ${args.city}. Coordinates: ${response.results[0].latitude}, " +
				"${response.results[0].longitude}. Country: ${response.results[0].country}.")).
		FallbackOutput(swaig.NewFunctionResult(
			"I couldn't find weather data for ${args.city} right now."))

	a.RegisterSwaigFunction(weather.ToSwaigFunction())

	return a
}
