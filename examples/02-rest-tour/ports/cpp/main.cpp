// Workshop REST tour — Pillar 2 (C++ CLI).
//
//   ./rest-tour <project_id> <space> <token>

#include <signalwire/rest/rest_client.hpp>
#include <iostream>
#include <string>

using namespace signalwire;

template <typename T>
static void print(const std::string& label, const T& value) {
    std::cout << "\n=== " << label << " ===\n" << value << "\n";
}

int main(int argc, char** argv) {
    if (argc < 4) {
        std::cerr << "Usage: rest-tour <project_id> <space> <token>\n";
        return 1;
    }

    rest::RestClient client(argv[1], argv[3], argv[2]);

    try {
        print("client.phone_numbers.list(limit=20)",
              client.phone_numbers().list({{"limit", 20}}).dump(2));
    } catch (const std::exception& e) {
        std::cerr << "list failed: " << e.what() << "\n";
    }

    if (argc >= 6) {
        std::string from = argv[4], to = argv[5];
        try {
            print("client.compat.messages.create",
                  client.compat().messages().create({
                      {"from", from}, {"to", to},
                      {"body", "Hello from the SignalWire workshop!"}
                  }).dump(2));
        } catch (const std::exception& e) {
            std::cerr << "sms failed: " << e.what() << "\n";
        }
    }

    try {
        print("client.compat.calls.list(page_size=10)",
              client.compat().calls().list({{"page_size", 10}}).dump(2));
    } catch (const std::exception& e) {
        std::cerr << "calls list failed: " << e.what() << "\n";
    }

    return 0;
}
