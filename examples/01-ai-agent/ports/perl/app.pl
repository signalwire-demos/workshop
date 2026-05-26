#!/usr/bin/env perl
# Workshop AI Agent — Pillar 1 (Perl).
# Mojolicious::Lite app that hosts the workshop UI + a SignalWire AgentBase.
#
#   cpanm --installdeps .
#   perl app.pl daemon -l http://0.0.0.0:8000

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(decode_json encode_json);

use SignalWire::Agent::AgentBase;
use SignalWire::DataMap;
use SignalWire::SWAIG::FunctionResult;
use SignalWire::REST::RestClient;

my $SHARED_UI = "$Bin/../../../../shared/ui";
my %STATE;
my $AGENT = build_agent();

sub build_agent {
    my $a = SignalWire::Agent::AgentBase->new(name => 'workshop-agent', route => '/agent');

    $a->add_language(
        name => 'English', code => 'en-US', voice => 'rime.spore',
        speech_fillers => [qw(Um Well Sure)],
    );
    $a->prompt_add_section('Personality',
        'You are a friendly demo assistant in a SignalWire workshop. '
        . 'Sound warm and natural, keep replies short.');
    $a->prompt_add_section('Greeting',
        'Greet the caller, say you\'re the workshop demo agent, '
        . 'and ask what they\'d like to try.');
    $a->prompt_add_section('Capabilities', undef, [
        'tell_joke — tell a dad joke from icanhazdadjoke',
        'get_weather — current weather for a city',
        'datetime — current date and time anywhere',
        'math — arithmetic, percentages, conversions',
    ]);

    $a->add_skill('datetime');
    $a->add_skill('math');

    $a->define_tool(
        name => 'tell_joke',
        description => 'Tell a fresh dad joke from the icanhazdadjoke API. '
            . 'Use whenever the caller asks for a joke or wants entertainment.',
        parameters => { type => 'object', properties => {}, required => [] },
        handler => sub ($args, $raw) {
            my $ua = Mojo::UserAgent->new;
            my $res = eval { $ua->get('https://icanhazdadjoke.com/' => { Accept => 'application/json' })->result };
            if (!$res || !$res->is_success) {
                return SignalWire::SWAIG::FunctionResult->new(
                    'I had a joke about timeouts, but it never came back.');
            }
            my $joke = $res->json('/joke') // 'I had a joke about UDP, but you might not get it.';
            return SignalWire::SWAIG::FunctionResult->new($joke);
        },
    );

    my $weather = SignalWire::DataMap->new('get_weather')
        ->description('Get the current weather for a city. Use whenever the caller asks '
            . 'about weather, temperature, or conditions in any location.')
        ->parameter('city', 'string', 'The city name', required => 1)
        ->webhook('GET', 'https://geocoding-api.open-meteo.com/v1/search?name=${args.city}&count=1&format=json')
        ->output(SignalWire::SWAIG::FunctionResult->new(
            'I\'m looking up ${args.city}. Coordinates: '
            . '${response.results[0].latitude}, ${response.results[0].longitude}. '
            . 'Country: ${response.results[0].country}.'))
        ->fallback_output(SignalWire::SWAIG::FunctionResult->new(
            'I couldn\'t find weather data for ${args.city} right now.'));

    $a->register_swaig_function($weather->to_swaig_function);
    return $a;
}

get '/' => sub ($c) {
    $c->res->headers->content_type('text/html');
    $c->reply->file("$SHARED_UI/creds-form.html");
};

get '/demo.js' => sub ($c) {
    $c->res->headers->content_type('application/javascript');
    $c->reply->file("$Bin/demo.js");
};

# Static files for /shared/*
push @{app->static->paths}, $SHARED_UI;

post '/api/setup' => sub ($c) {
    my $data = $c->req->json // {};
    my ($pid, $sp, $tk) = map { ($data->{$_} // '') =~ s/^\s+|\s+$//gr } qw(project_id space token);
    return $c->render(json => { ok => \0, error => 'All fields required' }, status => 400)
        if !$pid || !$sp || !$tk;
    my $client = eval { SignalWire::REST::RestClient->new(project => $pid, token => $tk, host => $sp) };
    my $numbers = eval { $client->phone_numbers->list(limit => 20) };
    if ($@ || !$client) {
        return $c->render(json => { ok => \0, error => "Credential check failed: $@" }, status => 400);
    }
    $STATE{creds} = { project_id => $pid, space => $sp, token => $tk };
    $c->render(json => {
        ok => \1, jwt => '', subscriber_id => '',
        numbers => $numbers // [], agent_path => '/agent',
    });
};

post '/api/wire-number' => sub ($c) {
    return $c->render(json => { ok => \0, error => 'Run /api/setup first' }, status => 400)
        unless $STATE{creds};
    my $data = $c->req->json // {};
    my ($sid, $purl) = map { ($data->{$_} // '') =~ s/^\s+|\s+$//gr } qw(sid public_url);
    return $c->render(json => { ok => \0, error => 'sid + public_url required' }, status => 400)
        if !$sid || !$purl;
    my $creds = $STATE{creds};
    my $client = SignalWire::REST::RestClient->new(
        project => $creds->{project_id}, token => $creds->{token}, host => $creds->{space},
    );
    (my $voice_url = $purl) =~ s{/+$}{};
    $voice_url .= '/agent';
    my $r = eval { $client->phone_numbers->update($sid, voice_url => $voice_url, voice_method => 'POST') };
    return $c->render(json => { ok => \0, error => "$@" }, status => 400) if $@;
    $c->render(json => { ok => \1, voice_url => $voice_url });
};

# /agent and /agent/* — route to AgentBase's request handler. SignalWire's
# Perl AgentBase has its own runtime; here we expect a `handle_request($c)`
# entry point — adjust if your installed version uses a different name.
under '/agent' => sub ($c) {
    if ($AGENT->can('handle_request')) {
        $AGENT->handle_request($c);
        return 0;  # short-circuit further dispatch
    }
    $c->render(text => 'Agent handler not exposed by this SDK version', status => 500);
    return 0;
};

app->start;
