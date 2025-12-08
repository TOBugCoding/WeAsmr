#include "PageMgr.h"
#include <QDebug>
#include <QQuickItem>

PageMgr::PageMgr(QObject* parent) : QObject(parent) {
    // 修复：安全获取QML引擎（移除QQmlContext依赖）
    if (parent) {
        m_engine = qmlEngine(parent);
    }
    // 兜底：若父节点无引擎，使用全局默认引擎（Qt 6 兼容）
    if (!m_engine) {
        m_engine = new QQmlEngine(this);
    }
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
}

// 接口1：更新缓存Map
void PageMgr::freshmap(const QString& path, QQmlComponent* loader) {
    if (path.isEmpty() || !loader) {
        qWarning() << "[PageMgr] freshmap failed: invalid path or loader";
        return;
    }
    m_cacheMap[path] = loader;
    qDebug() << "[PageMgr] cache updated: " << path;
}

// 接口2：从Map获取缓存
void PageMgr::getmap(const QString& path) {
    if (path.isEmpty()) {
        emit pageLoadFailed(path);
        return;
    }

    QObject* page = createPageInstance(path);
    if (page) {
        m_currentPage = page;
        emit pageReady(page);
        emit currentPageChanged();
    }
    else {
        emit pageLoadFailed(path);
    }
}

// 核心修复：移除QQuickItem::setSizePolicy和Expanding（Qt 6 无此接口）
QObject* PageMgr::createPageInstance(const QString& path) {
    QQmlComponent* component = m_cacheMap.value(path);
    if (!component) {
        qDebug() << "[PageMgr] no cached component, create new: " << path;
        // Qt 6 标准创建Component（QUrl必须显式构造）
        component = new QQmlComponent(m_engine, QUrl(path), this);
        if (component->isError()) {
            qWarning() << "[PageMgr] component create error: " << component->errors();
            delete component;
            return nullptr;
        }
        m_cacheMap[path] = component;
    }

    // 创建页面实例
    QObject* page = component->create();
    if (!page) {
        qWarning() << "[PageMgr] create page instance failed: " << path;
        return nullptr;
    }

    // 修复：移除setSizePolicy，改用Qt 6 标准属性设置
    if (auto item = qobject_cast<QQuickItem*>(page)) {
        item->setVisible(false);
        item->setZ(0);
        // Qt 6 中QQuickItem无SizePolicy，改用anchors.fill或width/height绑定
        item->setWidth(0);  // 初始宽度（由QML侧anchors.fill覆盖）
        item->setHeight(0); // 初始高度（由QML侧anchors.fill覆盖）
    }

    qDebug() << "[PageMgr] page instance created: " << path;
    return page;
}