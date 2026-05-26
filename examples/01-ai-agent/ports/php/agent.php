<?php
/**
 * Workshop AI Agent — Pillar 1 reference (PHP).
 *
 * Mirror of the Python WorkshopAgent.
 */

declare(strict_types=1);

require_once __DIR__ . '/vendor/autoload.php';

use SignalWire\Agent\AgentBase;
use SignalWire\DataMap\DataMap;
use SignalWire\SWAIG\FunctionResult;

class WorkshopAgent extends AgentBase
{
    public function __construct()
    {
        parent::__construct(name: 'workshop-agent', route: '/agent');

        $this->addLanguage(
            name: 'English',
            code: 'en-US',
            voice: 'rime.spore',
            speechFillers: ['Um', 'Well', 'Sure'],
        );

        $this->promptAddSection(
            'Personality',
            'You are a friendly demo assistant in a SignalWire workshop. '
            . 'Sound warm and natural, keep replies short.',
        );
        $this->promptAddSection(
            'Greeting',
            'Greet the caller, say you\'re the workshop demo agent, '
            . 'and ask what they\'d like to try.',
        );
        $this->promptAddSection('Capabilities', '', [
            'tell_joke — tell a dad joke from icanhazdadjoke',
            'get_weather — current weather for a city',
            'datetime — current date and time anywhere',
            'math — arithmetic, percentages, conversions',
        ]);

        $this->addSkill('datetime');
        $this->addSkill('math');

        $this->defineTool(
            name: 'tell_joke',
            description: 'Tell a fresh dad joke from the icanhazdadjoke API. '
                . 'Use whenever the caller asks for a joke or wants entertainment.',
            parameters: ['type' => 'object', 'properties' => (object) [], 'required' => []],
            handler: function (array $args, $raw): FunctionResult {
                $ctx = stream_context_create([
                    'http' => [
                        'header' => "Accept: application/json\r\nUser-Agent: SignalWire-Workshop\r\n",
                        'timeout' => 5,
                    ],
                ]);
                $body = @file_get_contents('https://icanhazdadjoke.com/', false, $ctx);
                if ($body === false) {
                    return new FunctionResult('I had a joke about timeouts, but it never came back.');
                }
                $payload = json_decode($body, true);
                $joke = $payload['joke'] ?? 'I had a joke about UDP, but you might not get it.';
                return new FunctionResult($joke);
            },
        );

        $weather = (new DataMap('get_weather'))
            ->description(
                'Get the current weather for a city. Use whenever the caller asks '
                . 'about weather, temperature, or conditions in any location.'
            )
            ->parameter('city', 'string', 'The city name', required: true)
            ->webhook(
                'GET',
                'https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json',
            )
            ->output(new FunctionResult(
                'I\'m looking up ${args.city}. Coordinates: '
                . '${response.results[0].latitude}, ${response.results[0].longitude}. '
                . 'Country: ${response.results[0].country}.'
            ))
            ->fallbackOutput(new FunctionResult(
                'I couldn\'t find weather data for ${args.city} right now.'
            ));

        $this->registerSwaigFunction($weather->toSwaigFunction());
    }
}
