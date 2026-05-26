[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 2 — REST Tour (Ruby)

## Run

```bash
bundle install
ruby app.rb
# Open http://localhost:8001
```

Same UI flow as Python/TS. Sinatra serves the shared UI + 4 demo endpoints calling `SignalWire::REST::RestClient`.
