cmake_minimum_required(VERSION 3.16)
project(workshop_relay_realtime_cpp CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SIGNALWIRE_CPP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../signalwire-cpp"
    CACHE PATH "Path to signalwire-cpp clone")

if(NOT EXISTS "${SIGNALWIRE_CPP_ROOT}/CMakeLists.txt")
    message(FATAL_ERROR "signalwire-cpp not found at ${SIGNALWIRE_CPP_ROOT}.")
endif()

add_subdirectory("${SIGNALWIRE_CPP_ROOT}" signalwire-cpp-build EXCLUDE_FROM_ALL)

add_executable(relay-realtime main.cpp)
target_link_libraries(relay-realtime PRIVATE signalwire)
