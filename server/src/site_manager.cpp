#include "site_manager.h"
#include <fstream>
#include <iostream>
#include <algorithm>
#include <sys/stat.h>

using json = nlohmann::json;

// ---- SiteItem ----

json SiteItem::toJson() const {
    return {
        {"id", id},
        {"name", name},
        {"mainUrl", mainUrl},
        {"apiType", apiType},
        {"enabled", enabled},
        {"sortOrder", sortOrder}
    };
}

SiteItem SiteItem::fromJson(const json& obj) {
    SiteItem item;
    item.id          = obj.value("id", "");
    item.name        = obj.value("name", "");
    item.mainUrl     = obj.value("mainUrl", "");
    item.apiType     = obj.value("apiType", "alist");
    item.enabled     = obj.value("enabled", true);
    item.sortOrder   = obj.value("sortOrder", 0);
    return item;
}

// ---- 辅助：创建目录 ----

static void ensureDir(const std::string& path) {
    // 提取目录部分（去掉文件名）
    auto pos = path.rfind('/');
    if (pos == std::string::npos) pos = path.rfind('\\');
    if (pos == std::string::npos) return;
    std::string dir = path.substr(0, pos);
    if (dir.empty()) return;
    mkdir(dir.c_str(), 0755);
}

// ---- SiteManager ----

SiteManager::SiteManager(const std::string& dataPath)
    : m_dataPath(dataPath) {}

bool SiteManager::load() {
    std::ifstream file(m_dataPath);
    if (!file.is_open()) {
        std::cerr << "[SiteManager] 数据文件不存在，创建默认: " << m_dataPath << std::endl;

        // 创建默认数据
        json defaultSites = {
            {"sites", {
                {{"id","selfWeb"},  {"name","个人网盘"},  {"mainUrl","http://file.zjpzcmu.cn"},  {"apiType","alist"}, {"enabled",true}, {"sortOrder",0}},
                {{"id","panmidy"},  {"name","盘趣味"},    {"mainUrl","https://pan.lm379.cn"},    {"apiType","alist"}, {"enabled",true}, {"sortOrder",1}},
                {{"id","moon"},     {"name","ASMR Moon"}, {"mainUrl","https://asmrmoon.com"},    {"apiType","alist"}, {"enabled",true}, {"sortOrder",2}},
                {{"id","gay"},      {"name","ASMR Gay"},  {"mainUrl","https://www.asmrgay.com"}, {"apiType","alist"}, {"enabled",true}, {"sortOrder",3}}
            }}
        };

        ensureDir(m_dataPath);
        std::ofstream out(m_dataPath);
        if (!out.is_open()) {
            std::cerr << "[SiteManager] 无法创建数据文件: " << m_dataPath << std::endl;
            return false;
        }
        out << defaultSites.dump(4) << std::endl;
        out.close();

        // 重新打开读取
        file.open(m_dataPath);
        if (!file.is_open()) {
            return false;
        }
    }

    try {
        json doc = json::parse(file);
        file.close();

        json arr = doc.value("sites", json::array());
        m_sites.clear();
        for (const auto& val : arr) {
            if (val.is_object()) {
                m_sites.push_back(SiteItem::fromJson(val));
            }
        }

        std::sort(m_sites.begin(), m_sites.end(),
                  [](const SiteItem& a, const SiteItem& b) { return a.sortOrder < b.sortOrder; });

        std::cout << "[SiteManager] 加载 " << m_sites.size() << " 个网站" << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "[SiteManager] JSON 解析失败: " << e.what() << std::endl;
        return false;
    }
}

bool SiteManager::save() const {
    json arr = json::array();
    for (const auto& item : m_sites) {
        arr.push_back(item.toJson());
    }

    json root;
    root["sites"] = arr;

    std::ofstream file(m_dataPath, std::ios::trunc);
    if (!file.is_open()) {
        std::cerr << "[SiteManager] 无法写入: " << m_dataPath << std::endl;
        return false;
    }

    file << root.dump(4) << std::endl;
    file.close();
    return true;
}

std::vector<SiteItem> SiteManager::getAll() const {
    return m_sites;
}

std::vector<SiteItem> SiteManager::getEnabled() const {
    std::vector<SiteItem> result;
    for (const auto& item : m_sites) {
        if (item.enabled) {
            result.push_back(item);
        }
    }
    return result;
}

SiteItem SiteManager::getById(const std::string& id) const {
    for (const auto& item : m_sites) {
        if (item.id == id) return item;
    }
    return SiteItem();
}

bool SiteManager::contains(const std::string& id) const {
    for (const auto& item : m_sites) {
        if (item.id == id) return true;
    }
    return false;
}

bool SiteManager::addSite(const SiteItem& item) {
    if (item.id.empty()) {
        std::cerr << "[SiteManager] 添加失败: id 为空" << std::endl;
        return false;
    }
    if (contains(item.id)) {
        std::cerr << "[SiteManager] 添加失败: id 已存在: " << item.id << std::endl;
        return false;
    }
    m_sites.push_back(item);
    if (!save()) {
        m_sites.pop_back();
        return false;
    }
    std::cout << "[SiteManager] 添加成功: " << item.id << std::endl;
    return true;
}

bool SiteManager::removeSite(const std::string& id) {
    for (auto it = m_sites.begin(); it != m_sites.end(); ++it) {
        if (it->id == id) {
            SiteItem removed = *it;
            m_sites.erase(it);
            if (!save()) {
                m_sites.push_back(removed);
                return false;
            }
            std::cout << "[SiteManager] 删除成功: " << id << std::endl;
            return true;
        }
    }
    std::cerr << "[SiteManager] 删除失败: 未找到: " << id << std::endl;
    return false;
}
