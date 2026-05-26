#!/usr/bin/env perl
# Workshop REST tour — Pillar 2 (Perl).

use strict;
use warnings;
use FindBin qw($Bin);
use Mojolicious::Lite -signatures;
use SignalWire::REST::RestClient;

my $SHARED_UI = "$Bin/../../../../shared/ui";
my %STATE;

push @{app->static->paths}, $SHARED_UI;

sub _client { SignalWire::REST::RestClient->new(%{ $STATE{creds} // {} }); }

get '/' => sub ($c) { $c->res->headers->content_type('text/html'); $c->reply->file("$SHARED_UI/creds-form.html"); };
get '/demo.js' => sub ($c) { $c->res->headers->content_type('application/javascript'); $c->reply->file("$Bin/demo.js"); };

post '/api/setup' => sub ($c) {
    my $d = $c->req->json // {};
    my ($pid, $sp, $tk) = map { ($d->{$_} // '') =~ s/^\s+|\s+$//gr } qw(project_id space token);
    return $c->render(json => { ok => \0, error => 'All fields required' }, status => 400) if !$pid||!$sp||!$tk;
    eval { SignalWire::REST::RestClient->new(project=>$pid, token=>$tk, host=>$sp)->phone_numbers->list(limit=>1) };
    return $c->render(json => { ok => \0, error => "Credential check failed: $@" }, status => 400) if $@;
    $STATE{creds} = { project => $pid, token => $tk, host => $sp };
    $c->render(json => { ok => \1, jwt => 'session-validated', subscriber_id => 'n/a' });
};

get '/api/list-numbers' => sub ($c) {
    return $c->render(json => { ok => \0, error => 'Run setup first' }, status => 400) unless $STATE{creds};
    my $r = eval { _client()->phone_numbers->list(limit => 20) };
    return $c->render(json => { ok => \0, error => "$@" }, status => 400) if $@;
    $c->render(json => { ok => \1, sdk_call => '$client->phone_numbers->list(limit => 20)', response => $r });
};

post '/api/send-sms' => sub ($c) {
    return $c->render(json => { ok => \0, error => 'Run setup first' }, status => 400) unless $STATE{creds};
    my $d = $c->req->json // {};
    my ($from, $to, $body) = ($d->{from}, $d->{to}, $d->{body} // 'Hello from the SignalWire workshop!');
    return $c->render(json => { ok => \0, error => 'from + to required' }, status => 400) if !$from||!$to;
    my $r = eval { _client()->compat->messages->create(from=>$from, to=>$to, body=>$body) };
    return $c->render(json => { ok => \0, error => "$@" }, status => 400) if $@;
    $c->render(json => { ok => \1, sdk_call => qq{\$client->compat->messages->create(from=>'$from', to=>'$to', body=>...)}, response => $r });
};

get '/api/recent-calls' => sub ($c) {
    return $c->render(json => { ok => \0, error => 'Run setup first' }, status => 400) unless $STATE{creds};
    my $r = eval { _client()->compat->calls->list(page_size => 10) };
    return $c->render(json => { ok => \0, error => "$@" }, status => 400) if $@;
    $c->render(json => { ok => \1, sdk_call => '$client->compat->calls->list(page_size => 10)', response => $r });
};

post '/api/wire-number' => sub ($c) {
    return $c->render(json => { ok => \0, error => 'Run setup first' }, status => 400) unless $STATE{creds};
    my $d = $c->req->json // {};
    my ($sid, $vu) = ($d->{sid} // '', $d->{voice_url} // '');
    return $c->render(json => { ok => \0, error => 'sid + voice_url required' }, status => 400) if !$sid||!$vu;
    my $r = eval { _client()->phone_numbers->update($sid, voice_url => $vu, voice_method => 'POST') };
    return $c->render(json => { ok => \0, error => "$@" }, status => 400) if $@;
    $c->render(json => { ok => \1, sdk_call => qq{\$client->phone_numbers->update('$sid', voice_url => '$vu')}, response => $r });
};

app->start;
