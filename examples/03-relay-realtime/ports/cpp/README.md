[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 3 — RELAY Realtime (C++) — CLI only

CLI prints events to stdout instead of streaming to a browser.

## Sketch

```cpp
#include <signalwire/relay.h>

int main(int argc, char** argv) {
    auto client = signalwire::RelayClient(argv[1], argv[3], argv[2], {"workshop"});
    client.on_call([](auto& call) {
        std::cout << "{\"kind\":\"call\",\"call_id\":\"" << call.call_id() << "\"}\n";
        call.answer();
    });
    client.connect();
    // block; events stream to stdout
}
```
