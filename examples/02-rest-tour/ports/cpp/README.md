# Pillar 2 — REST Tour (C++) — CLI only

C++ port has no web UI (see Pillar 1 README for rationale). The CLI runs each REST tour action sequentially.

## Build

```bash
mkdir build && cd build
cmake ..
make
./rest-tour <project_id> <space> <token>
```

Sketch:

```cpp
#include <signalwire/rest.h>

int main(int argc, char** argv) {
    auto client = signalwire::RestClient(argv[1], argv[3], argv[2]);

    auto numbers = client.phone_numbers().list({{"limit", 20}});
    auto msg = client.compat().messages().create({{"from","..."},{"to","..."},{"body","..."}});
    auto calls = client.compat().calls().list({{"page_size", 10}});
    // print each
}
```
