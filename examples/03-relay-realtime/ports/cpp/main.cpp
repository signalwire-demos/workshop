// Workshop RELAY realtime — Pillar 3 (C++ CLI).
//
// Streams events to stdout as JSON lines. Optional --dial from to
// triggers an outbound call after a brief connect delay.
//
//   ./relay-realtime <project_id> <space> <token> [--dial <from> <to>]

#include <signalwire/relay/client.hpp>
#include <iostream>
#include <string>
#include <chrono>
#include <thread>

using namespace signalwire;

int main(int argc, char** argv) {
    if (argc < 4) {
        std::cerr << "Usage: relay-realtime <project_id> <space> <token> [--dial <from> <to>]\n";
        return 1;
    }
    std::string project = argv[1], space = argv[2], token = argv[3];

    std::string dial_from, dial_to;
    for (int i = 4; i + 2 < argc; ++i) {
        if (std::string(argv[i]) == "--dial") {
            dial_from = argv[i + 1];
            dial_to = argv[i + 2];
        }
    }

    relay::RelayClient client(project, token, space, {"workshop"});

    client.on_call([](const relay::Call& call) {
        std::cout << "{\"kind\":\"call\",\"state\":\"incoming\",\"call_id\":\""
                  << call.call_id() << "\"}\n" << std::flush;
        // call.answer() would be invoked here in a real handler.
    });

    if (!client.connect()) {
        std::cerr << "RELAY connect failed\n";
        return 1;
    }
    std::cout << "{\"kind\":\"system\",\"message\":\"RELAY connected\"}\n" << std::flush;

    if (!dial_from.empty()) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        try {
            auto call = client.dial({{{
                {"type", "phone"}, {"from", dial_from}, {"to", dial_to}, {"timeout", 30}
            }}});
            std::cout << "{\"kind\":\"dial\",\"call_id\":\"" << call.call_id()
                      << "\"}\n" << std::flush;
        } catch (const std::exception& e) {
            std::cerr << "{\"kind\":\"error\",\"message\":\"" << e.what() << "\"}\n";
        }
    }

    // Block forever; events stream via the on_call callback.
    while (client.is_connected()) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    return 0;
}
