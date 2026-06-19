#pragma once
#include <string>
#include <vector>
#include <nlohmann/json.hpp>

struct SiteItem {
    std::string id;
    std::string name;
    std::string mainUrl;
    std::string apiType = "alist";
    bool enabled = true;
    int sortOrder = 0;

    nlohmann::json toJson() const;
    static SiteItem fromJson(const nlohmann::json& obj);
};

class SiteManager {
public:
    explicit SiteManager(const std::string& dataPath);

    bool load();
    bool save() const;

    std::vector<SiteItem> getAll() const;
    std::vector<SiteItem> getEnabled() const;
    SiteItem getById(const std::string& id) const;
    bool contains(const std::string& id) const;

    bool addSite(const SiteItem& item);
    bool removeSite(const std::string& id);

private:
    std::string m_dataPath;
    std::vector<SiteItem> m_sites;
};
