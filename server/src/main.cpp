#include <iostream>
#include <httplib.h>
#include <nlohmann/json.hpp>
#include "config.h"
#include "site_manager.h"

using json = nlohmann::json;

// 提取 Bearer token
static std::string extractToken(const httplib::Request& req) {
    auto it = req.headers.find("Authorization");
    if (it == req.headers.end()) return "";
    const std::string& auth = it->second;
    if (auth.size() > 7 && auth.substr(0, 7) == "Bearer ") {
        return auth.substr(7);
    }
    return "";
}

int main() {
    std::cout << "=== ASMR Site Server ===" << std::endl;

    // 加载配置
    ServerConfig cfg = loadServerConfig();

    // 初始化网站管理器
    SiteManager siteMgr(cfg.sitesDataPath);
    if (!siteMgr.load()) {
        std::cerr << "网站数据加载失败，启动中止" << std::endl;
        return 1;
    }

    httplib::Server svr;

    // GET /api/sites — 公开，返回启用的网站列表
    svr.Get("/api/sites", [&](const httplib::Request&, httplib::Response& res) {
        auto sites = siteMgr.getEnabled();

        json arr = json::array();
        for (const auto& item : sites) {
            arr.push_back(item.toJson());
        }

        json resp;
        resp["code"] = 0;
        resp["message"] = "ok";
        resp["data"] = arr;

        res.set_content(resp.dump(), "application/json");
    });

    // POST /api/sites — 需 token，添加网站
    svr.Post("/api/sites", [&](const httplib::Request& req, httplib::Response& res) {
        std::string token = extractToken(req);
        if (token != cfg.internalToken) {
            json resp = {{"code", 403}, {"message", "Forbidden: invalid token"}};
            res.status = 403;
            res.set_content(resp.dump(), "application/json");
            return;
        }

        json body;
        try {
            body = json::parse(req.body);
        } catch (const std::exception&) {
            json resp = {{"code", 400}, {"message", "Invalid JSON body"}};
            res.status = 400;
            res.set_content(resp.dump(), "application/json");
            return;
        }

        SiteItem item = SiteItem::fromJson(body);
        if (item.id.empty() || item.mainUrl.empty()) {
            json resp = {{"code", 400}, {"message", "Missing required fields: id, mainUrl"}};
            res.status = 400;
            res.set_content(resp.dump(), "application/json");
            return;
        }
        if (item.apiType.empty()) item.apiType = "alist";

        if (siteMgr.addSite(item)) {
            json resp = {{"code", 0}, {"message", "site added"}, {"data", item.toJson()}};
            res.status = 201;
            res.set_content(resp.dump(), "application/json");
        } else {
            json resp = {{"code", 409}, {"message", "Site id already exists or save failed"}};
            res.status = 409;
            res.set_content(resp.dump(), "application/json");
        }
    });

    // DELETE /api/sites/:id — 需 token，删除网站
    svr.Delete(R"(/api/sites/(\w+))", [&](const httplib::Request& req, httplib::Response& res) {
        std::string token = extractToken(req);
        if (token != cfg.internalToken) {
            json resp = {{"code", 403}, {"message", "Forbidden: invalid token"}};
            res.status = 403;
            res.set_content(resp.dump(), "application/json");
            return;
        }

        std::string siteId = req.matches[1];
        if (siteMgr.removeSite(siteId)) {
            json resp = {{"code", 0}, {"message", "site removed"}};
            res.set_content(resp.dump(), "application/json");
        } else {
            json resp = {{"code", 404}, {"message", "Site not found"}};
            res.status = 404;
            res.set_content(resp.dump(), "application/json");
        }
    });

    // CORS 预检
    svr.Options(R"(/api/sites.*)", [](const httplib::Request&, httplib::Response& res) {
        res.set_header("Access-Control-Allow-Origin", "*");
        res.set_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
        res.set_header("Access-Control-Allow-Headers", "Content-Type, Authorization");
        res.status = 204;
    });

    // 全局 CORS 头
    svr.set_post_routing_handler([](const httplib::Request&, httplib::Response& res) {
        res.set_header("Access-Control-Allow-Origin", "*");
    });

    std::cout << "服务器就绪，端口: " << cfg.port << std::endl;

    if (!svr.listen("0.0.0.0", cfg.port)) {
        std::cerr << "启动失败" << std::endl;
        return 1;
    }

    return 0;
}
