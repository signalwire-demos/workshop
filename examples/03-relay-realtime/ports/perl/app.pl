#!/usr/bin/env perl
# Workshop RELAY realtime — Pillar 3 (Perl).
# Mojolicious has native WebSocket support via the websocket route.

use strict;
use warnings;
use FindBin qw($Bin);
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(encode_json);
use SignalWire::REST::RestClient;
use SignalWire::Relay::Client;

my $SHARED_UI = "$Bin/../../../../shared/ui";
my %STATE;
my @SUBS;  # list of Mojo::Transaction::WebSocket controllers

sub _broadcast ($event) {
    my $json = encode_json($event);
    @SUBS = grep { $_->tx && !$_->tx->is_finished } @SUBS;
    $_->send($json) for @SUBS;
}

push @{app->static->paths}, $SHARED_UI;

get '/' => sub ($c) { $c->res->headers->content_type('text/html'); $c->reply->file("$SHARED_UI/creds-form.html"); };
get '/demo.js' => sub ($c) { $c->res->headers->content_type('application/javascript'); $c->reply->file("$Bin/demo.js"); };

post '/api/setup' => sub ($c) {
    my $d = $c->req->json // {};
    my ($pid, $sp, $tk) = map { ($d->{$_} // '') =~ s/^\s+|\s+$//gr } qw(project_id space token);
    return $c->render(json => { ok => \0, error => 'All fields required' }, status => 400) if !$pid||!$sp||!$tk;
    eval { SignalWire::REST::RestClient->new(project=>$pid, token=>$tk, host=>$sp)->phone_numbers->list(limit=>1) };
    return $c->render(json => { ok => \0, error => "Credential check failed: $@" }, status => 400) if $@;

    if ($STATE{relay}) { eval { $STATE{relay}->disconnect }; delete $STATE{relay}; }

    my $rl = SignalWire::Relay::Client->new(
        project => $pid, token => $tk, host => $sp, contexts => ['workshop'],
    );
    $rl->on_call(sub ($call) {
        _broadcast({ kind => 'call', state => 'incoming', call_id => $call->call_id });
        my $ok = eval { $call->answer; 1 };
        if ($ok) {
            _broadcast({ kind => 'call', state => 'answered', call_id => $call->call_id });
        } else {
            _broadcast({ kind => 'error', message => "answer failed: $@" });
        }
    });

    # Non-blocking connect via Mojo's IOLoop.
    Mojo::IOLoop->next_tick(sub {
        eval { $rl->connect; _broadcast({ kind => 'system', message => 'RELAY connected' }); };
        _broadcast({ kind => 'error', message => "RELAY connect failed: $@" }) if $@;
    });

    $STATE{creds} = { project => $pid, token => $tk, host => $sp };
    $STATE{relay} = $rl;
    $c->render(json => { ok => \1, jwt => 'session-validated', subscriber_id => 'n/a' });
};

websocket '/ws/events' => sub ($c) {
    push @SUBS, $c;
    if ($STATE{relay}) {
        $c->send(encode_json({ kind => 'system', message => 'ws connected' }));
    } else {
        $c->send(encode_json({ kind => 'error', message => 'Run setup first' }));
    }
    $c->on(finish => sub { @SUBS = grep { $_ != $c } @SUBS; });
};

post '/api/dial' => sub ($c) {
    return $c->render(json => { ok => \0, error => 'Run setup first' }, status => 400) unless $STATE{relay};
    my $d = $c->req->json // {};
    my ($from, $to) = ($d->{from} // '', $d->{to} // '');
    return $c->render(json => { ok => \0, error => 'from + to required' }, status => 400) if !$from||!$to;
    my $call = eval {
        $STATE{relay}->dial([[{ type => 'phone', from => $from, to => $to, timeout => 30 }]]);
    };
    return $c->render(json => { ok => \0, error => "$@" }, status => 400) if $@;
    $c->render(json => { ok => \1, call_id => $call->call_id });
};

app->start;
