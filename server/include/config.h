#pragma once
#include <string>

struct ServerConfig {
    int port = 8080;
    std::string internalToken;
    std::string sitesDataPath = "data/sites.json";
};

// 读取 server.json，不存在时用默认值并生成模板
ServerConfig loadServerConfig(const std::string& configPath = "server.json");
