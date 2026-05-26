# Pillar 1 — AI Agent

A phone-answering AI assistant with four capabilities, demonstrating the three SignalWire ways to add agent capabilities.

## What the agent does

- **Greeting** — picks up the phone, introduces itself.
- **Datetime skill** — built-in: "what time is it in Tokyo?" → answers from a one-line skill registration.
- **Joke (custom SWAIG function)** — you write the handler, the agent calls it.
- **Weather (DataMap)** — declarative: agent calls a public weather API serverlessly, no handler code on your side.

## Three ways to give an agent capabilities

| Method | Where logic runs | When to use |
|---|---|---|
| **Skill** | Built-in, server-side | Common capabilities (datetime, math, web search) |
| **Custom SWAIG function** | Your backend | Anything you can write in your language |
| **DataMap** | SignalWire-side, declarative | Calling a public HTTP API with no auth complexity |

## Per-language implementations

| Language | Status | Path |
|---|---|---|
| Python (reference) | ✅ | [`python/`](python/) |
| TypeScript (closing demo) | ✅ | [`typescript/`](typescript/) |
| Ruby | 🚧 | [`ports/ruby/`](ports/ruby/) |
| Go | 🚧 | [`ports/go/`](ports/go/) |
| Java | 🚧 | [`ports/java/`](ports/java/) |
| Perl | 🚧 | [`ports/perl/`](ports/perl/) |
| Rust | 🚧 | [`ports/rust/`](ports/rust/) |
| PHP | 🚧 | [`ports/php/`](ports/php/) |
| .NET | 🚧 | [`ports/dotnet/`](ports/dotnet/) |
| C++ | 🚧 | [`ports/cpp/`](ports/cpp/) (CLI only — no web UI) |

Each per-language directory has its own `README.md` with run instructions.
