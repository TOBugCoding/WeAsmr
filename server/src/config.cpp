#include "config.h"
#include <nlohmann/json.hpp>
#include <fstream>
#include <iostream>

using json = nlohmann::json;

ServerConfig loadServerConfig(const std::string& configPath) {
    ServerConfig cfg;

    std::ifstream file(configPath);
    if (!file.is_open()) {
        // 生成默认模板
        json obj;
        obj["port"] = cfg.port;
        obj["internalToken"] = "change-me-to-a-secret-token";
        obj["sitesDataPath"] = cfg.sitesDataPath;

        std::ofstream out(configPath);
        if (out.is_open()) {
            out << obj.dump(4) << std::endl;
            out.close();
            std::cout << "[Config] 已生成默认配置文件: " << configPath << std::endl;
        }
        return cfg;
    }

    try {
        json obj = json::parse(file);
        file.close();

        if (obj.contains("port"))           cfg.port = obj["port"].get<int>();
        if (obj.contains("internalToken"))  cfg.internalToken = obj["internalToken"].get<std::string>();
        if (obj.contains("sitesDataPath"))  cfg.sitesDataPath = obj["sitesDataPath"].get<std::string>();
    } catch (const std::exception& e) {
        std::cerr << "[Config] 解析配置文件失败: " << e.what() << std::endl;
    }

    std::cout << "[Config] 加载配置: port=" << cfg.port
              << " sitesDataPath=" << cfg.sitesDataPath << std::endl;
    return cfg;
}
