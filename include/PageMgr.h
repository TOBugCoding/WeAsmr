#pragma once

#include <QObject>
#include <QString>
#include <QMap>
#include <QQmlComponent>
#include <QQmlEngine>

class PageMgr : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* currentPage READ currentPage NOTIFY currentPageChanged)

public:
    static PageMgr* getInstance(QObject* parent = nullptr) {
        static PageMgr instance(parent);
        return &instance;
    }

    // 核心接口1：更新缓存Map
    Q_INVOKABLE void freshmap(const QString& path, QQmlComponent* loader);
    // 核心接口2：从Map获取缓存
    Q_INVOKABLE void getmap(const QString& path);

    QObject* currentPage() const { return m_currentPage; }

signals:
    void pageReady(QObject* page);
    void currentPageChanged();
    void pageLoadFailed(const QString& path);

private:
    explicit PageMgr(QObject* parent = nullptr);
    ~PageMgr() override = default;

    // 禁止拷贝
    PageMgr(const PageMgr&) = delete;
    PageMgr& operator=(const PageMgr&) = delete;

    // 内部创建页面实例（移除setSizePolicy）
    QObject* createPageInstance(const QString& path);

private:
    QMap<QString, QQmlComponent*> m_cacheMap;
    QObject* m_currentPage = nullptr;
    QQmlEngine* m_engine = nullptr; // 仅保留引擎，移除QQmlContext
};