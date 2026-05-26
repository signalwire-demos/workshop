# Pillar 2 — REST API Tour

Programmatic control of your SignalWire account via the REST SDK. The same `RestClient` your AI agent uses, exercised against the resources you'll touch most.

## What the tour covers

| Action | API | Demo button in UI |
|---|---|---|
| List phone numbers in your account | `client.incoming_phone_numbers.list()` | "List numbers" |
| Send an SMS | `client.messages.create(from_=..., to=..., body=...)` | "Send a test SMS" |
| Fetch recent call history | `client.calls.list(limit=10)` | "Show recent calls" |
| Wire a number to your agent | `client.incoming_phone_numbers(sid).update(voice_url=...)` | "Point a number at my agent" |

Each button shows the actual SDK call (left pane) and the response (right pane), so attendees see method ↔ output side by side.

## Per-language implementations

| Language | Status | Path |
|---|---|---|
| Python (reference) | ✅ | [`python/`](python/) |
| TypeScript (closing demo) | ✅ | [`typescript/`](typescript/) |
| Ruby | ✅ | [`ports/ruby/`](ports/ruby/) |
| Go | ✅ | [`ports/go/`](ports/go/) |
| Java / Perl / Rust / PHP / .NET / C++ | 🚧 | `ports/<lang>/` (pending) |
