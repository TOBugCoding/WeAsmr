cmake_minimum_required(VERSION 3.14)
project(AsmrSiteServer VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# cpp-httplib: 单头文件 HTTP 服务器
FetchContent_Declare(httplib
    GIT_REPOSITORY https://github.com/yhirose/cpp-httplib.git
    GIT_TAG        v0.15.3
    GIT_SHALLOW    TRUE
)

# nlohmann/json: 单头文件 JSON 库
FetchContent_Declare(json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG        v3.11.3
    GIT_SHALLOW    TRUE
)

FetchContent_MakeAvailable(httplib json)

add_executable(AsmrSiteServer
    src/main.cpp
    src/config.cpp
    src/site_manager.cpp
)

target_include_directories(AsmrSiteServer PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(AsmrSiteServer PRIVATE
    httplib::httplib
    nlohmann_json::nlohmann_json
    pthread
)
