# frozen_string_literal: true

# Workshop AI Agent — Pillar 1 reference (Ruby).
#
# Mirror of the Python WorkshopAgent. Same 3 ways to give an agent a capability:
#   1. add_skill        — built-in, one-liner
#   2. define_tool      — your handler
#   3. DataMap          — declarative, server-side

require 'signalwire'
require 'net/http'
require 'json'

class WorkshopAgent < SignalWire::AgentBase
  def initialize
    super(name: 'workshop-agent', route: '/agent')

    add_language(
      name: 'English',
      code: 'en-US',
      voice: 'rime.spore',
      speech_fillers: %w[Um Well Sure],
    )

    prompt_add_section(
      'Personality',
      'You are a friendly demo assistant in a SignalWire workshop. ' \
        'Sound warm and natural, keep replies short.',
    )
    prompt_add_section(
      'Greeting',
      "Greet the caller, say you're the workshop demo agent, " \
        "and ask what they'd like to try.",
    )
    prompt_add_section(
      'Capabilities',
      nil,
      bullets: [
        'tell_joke — tell a dad joke from icanhazdadjoke',
        'get_weather — current weather for a city',
        'datetime — current date and time anywhere',
        'math — arithmetic, percentages, conversions',
      ],
    )

    add_skill('datetime')
    add_skill('math')

    define_tool(
      name: 'tell_joke',
      description: 'Tell a fresh dad joke from the icanhazdadjoke API.',
      parameters: { type: 'object', properties: {}, required: [] },
      handler: ->(_args, _raw) {
        begin
          uri = URI('https://icanhazdadjoke.com/')
          req = Net::HTTP::Get.new(uri, 'Accept' => 'application/json',
                                       'User-Agent' => 'SignalWire-Workshop')
          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
          joke = JSON.parse(res.body).fetch('joke', 'I had a joke about UDP, but you might not get it.')
          SignalWire::SWAIG::FunctionResult.new(joke)
        rescue StandardError
          SignalWire::SWAIG::FunctionResult.new("I had a joke about timeouts, but it never came back.")
        end
      },
    )

    weather = SignalWire::DataMap.new('get_weather')
      .description(
        'Get the current weather for a city. Use whenever the caller asks ' \
        'about weather, temperature, or conditions in any location.',
      )
      .parameter('city', 'string', 'The city name', required: true)
      .webhook(
        'GET',
        'https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json',
      )
      .output(SignalWire::SWAIG::FunctionResult.new(
        "I'm looking up \${args.city}. Coordinates: " \
        '${response.results[0].latitude}, ${response.results[0].longitude}. ' \
        'Country: ${response.results[0].country}.',
      ))
      .fallback_output(SignalWire::SWAIG::FunctionResult.new(
        "I couldn't find weather data for \${args.city} right now.",
      ))

    register_swaig_function(weather.to_swaig_function)
  end
end
