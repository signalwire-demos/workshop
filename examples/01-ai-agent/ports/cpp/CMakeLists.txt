cmake_minimum_required(VERSION 3.16)
project(workshop_ai_agent_cpp CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Locate signalwire-cpp source tree (cloned adjacent to the workshop).
set(SIGNALWIRE_CPP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../signalwire-cpp"
    CACHE PATH "Path to signalwire-cpp clone")

if(NOT EXISTS "${SIGNALWIRE_CPP_ROOT}/CMakeLists.txt")
    message(FATAL_ERROR
        "signalwire-cpp not found at ${SIGNALWIRE_CPP_ROOT}.\n"
        "Clone it next to the workshop:\n"
        "  git clone https://github.com/signalwire/signalwire-cpp.git ${SIGNALWIRE_CPP_ROOT}")
endif()

add_subdirectory("${SIGNALWIRE_CPP_ROOT}" signalwire-cpp-build EXCLUDE_FROM_ALL)

find_package(CURL REQUIRED)

add_executable(workshop-agent main.cpp)
target_link_libraries(workshop-agent PRIVATE signalwire CURL::libcurl)
