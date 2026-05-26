# Pillar 1 — AI Agent (Ruby)

Parity port. Same UI, same behavior, idiomatic Ruby.

## Run

```bash
bundle install
ruby app.rb
# Open http://localhost:8000
```

## Stack

| Piece | Ruby version |
|---|---|
| Web framework | Sinatra |
| Server | Puma |
| Routing | Rack::Builder (Sinatra UI + AgentBase rack app + static files) |
| SignalWire SDK | `gem 'signalwire'` |

Method names follow Ruby idioms: `add_skill` (not `addSkill`), `define_tool` (not `defineTool`), `prompt_add_section` (snake_case).
