# Pillar 1 — AI Agent (C++) — CLI only

The C++ port intentionally skips the workshop UI — no idiomatic
zero-config web stack in C++ that pairs cleanly with the workshop's
"paste creds in browser" pattern. C++ users get a CLI agent and use the
SignalWire dashboard or the Python/TS REST tour to wire up the phone
number.

## Build

```bash
mkdir build && cd build
cmake ..
make
./workshop-agent
# Then point a SignalWire number's voice webhook at http://<your-host>:8000/agent
```

## Sketch — minimal C++ workshop agent

```cpp
#include <signalwire/agent.h>
#include <signalwire/datamap.h>

int main() {
    signalwire::AgentBase agent("workshop-agent", "/agent");

    agent.add_skill("datetime");
    agent.add_skill("math");

    agent.define_tool({
        .name = "tell_joke",
        .description = "Tell a fresh dad joke.",
        .parameters = { {"type", "object"}, {"properties", {}}, {"required", {}} },
        .handler = [](auto args, auto raw) {
            // fetch icanhazdadjoke, return FunctionResult
            return signalwire::FunctionResult("...");
        }
    });

    agent.run(8000);
    return 0;
}
```

Build setup is `CMakeLists.txt` linking against the `signalwire` library
from a sibling clone of `signalwire-cpp` (C++ has no CMake-native
registry; the SDK README documents the install).
