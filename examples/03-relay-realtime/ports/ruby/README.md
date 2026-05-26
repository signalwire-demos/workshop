[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 3 — RELAY Realtime (Ruby)

```bash
bundle install
ruby app.rb
# Open http://localhost:8002
```

Sinatra + `faye-websocket-ruby` + EventMachine. Thin is the Rack handler (Puma doesn't play well with Rack-hijack WS upgrades).

`SignalWire::Relay::Client#on_call` broadcasts to all attached WebSockets.
