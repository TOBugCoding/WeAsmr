#pragma once
#include <QString>
#include <QList>
#include <QJsonObject>
#include <algorithm>

// 网站条目（纯数据结构，不参与QML注册）
struct SiteItem {
    QString id;          // 唯一标识，如 "moon", "gay"
    QString name;        // 显示名称
    QString mainUrl;     // API 主站地址
    QString apiType;     // API 类型（预留，当前固定 "alist"）
    bool enabled = true;
    int sortOrder = 0;

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["name"] = name;
        obj["mainUrl"] = mainUrl;
        obj["apiType"] = apiType;
        obj["enabled"] = enabled;
        obj["sortOrder"] = sortOrder;
        return obj;
    }

    static SiteItem fromJson(const QJsonObject& obj) {
        SiteItem item;
        item.id = obj["id"].toString();
        item.name = obj["name"].toString();
        item.mainUrl = obj["mainUrl"].toString();
        item.apiType = obj["apiType"].toString("alist");
        item.enabled = obj["enabled"].toBool(true);
        item.sortOrder = obj["sortOrder"].toInt(0);
        return item;
    }
};

class webAddr {
public:
    static webAddr& GetInstance() {
        static webAddr instance;
        return instance;
    }

    // 从远程/本地加载网站列表（替换旧列表）
    void loadSites(QList<SiteItem> sites) {
        // 记录当前选中的站点 id
        QString currentId;
        if (m_currentIndex >= 0 && m_currentIndex < m_sites.size()) {
            currentId = m_sites[m_currentIndex].id;
        }
        // 按 sortOrder 排序
        std::sort(sites.begin(), sites.end(),
                  [](const SiteItem& a, const SiteItem& b) { return a.sortOrder < b.sortOrder; });
        m_sites = sites;
        // 按 id 恢复选中，找不到则选第一个
        m_currentIndex = -1;
        if (!currentId.isEmpty()) {
            for (int i = 0; i < m_sites.size(); ++i) {
                if (m_sites[i].id == currentId && m_sites[i].enabled) {
                    m_currentIndex = i;
                    break;
                }
            }
        }
        if (m_currentIndex < 0 && !m_sites.isEmpty()) {
            m_currentIndex = 0;
        }
    }

    // 添加单个站点（同 id 则更新），按 sortOrder 插入
    void addSite(const SiteItem& item) {
        for (int i = 0; i < m_sites.size(); ++i) {
            if (m_sites[i].id == item.id) {
                m_sites[i] = item;
                return;
            }
        }
        m_sites.append(item);
        std::sort(m_sites.begin(), m_sites.end(),
                  [](const SiteItem& a, const SiteItem& b) { return a.sortOrder < b.sortOrder; });
    }

    // 按 id 移除站点
    bool removeSite(const QString& id) {
        for (int i = 0; i < m_sites.size(); ++i) {
            if (m_sites[i].id == id) {
                m_sites.removeAt(i);
                if (m_currentIndex >= m_sites.size()) {
                    m_currentIndex = m_sites.isEmpty() ? -1 : m_sites.size() - 1;
                }
                return true;
            }
        }
        return false;
    }

    // 返回当前站点数
    int siteCount() const { return m_sites.size(); }

    // 切换到指定 id 的网站，成功返回 true
    bool switchTo(const QString& id) {
        for (int i = 0; i < m_sites.size(); ++i) {
            if (m_sites[i].id == id && m_sites[i].enabled) {
                m_currentIndex = i;
                return true;
            }
        }
        return false;
    }

    // 获取当前网站信息
    QString getMainweb() const {
        if (m_currentIndex >= 0 && m_currentIndex < m_sites.size()) {
            return m_sites[m_currentIndex].mainUrl;
        }
        return {};
    }

    QString currentId() const {
        if (m_currentIndex >= 0 && m_currentIndex < m_sites.size()) {
            return m_sites[m_currentIndex].id;
        }
        return {};
    }

    QString currentName() const {
        if (m_currentIndex >= 0 && m_currentIndex < m_sites.size()) {
            return m_sites[m_currentIndex].name;
        }
        return {};
    }

    // 返回所有网站（供 QML 显示）
    QList<SiteItem> allSites() const { return m_sites; }

    // 返回所有网站名称列表
    QStringList siteNames() const {
        QStringList names;
        for (const SiteItem& item : m_sites) {
            if (item.enabled) {
                names.append(item.name);
            }
        }
        return names;
    }

    // 返回启用的网站列表（与 siteNames 索引一致）
    QList<SiteItem> enabledSites() const {
        QList<SiteItem> result;
        for (const SiteItem& item : m_sites) {
            if (item.enabled) {
                result.append(item);
            }
        }
        return result;
    }

    // 根据显示名称反查 id
    QString idFromName(const QString& name) const {
        for (const SiteItem& item : m_sites) {
            if (item.name == name) {
                return item.id;
            }
        }
        return {};
    }

    // 根据 id 查找 name
    QString nameFromId(const QString& id) const {
        for (const SiteItem& item : m_sites) {
            if (item.id == id) {
                return item.name;
            }
        }
        return {};
    }

    // 兼容旧代码：检查当前站点 id
    bool isCurrentId(const QString& id) const {
        return currentId() == id;
    }

    // 禁止拷贝和赋值
    webAddr(const webAddr&) = delete;
    webAddr& operator=(const webAddr&) = delete;

private:
    webAddr() = default;
    ~webAddr() = default;

    QList<SiteItem> m_sites;
    int m_currentIndex = -1;
};
