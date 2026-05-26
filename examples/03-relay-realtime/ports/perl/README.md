# Pillar 3 — RELAY Realtime (Perl)

```bash
cpanm --installdeps .
perl app.pl daemon -l http://0.0.0.0:8002
```

Mojolicious::Lite with native `websocket` route + `SignalWire::Relay::Client` + `on_call` handler broadcasting to all WS subscribers.
