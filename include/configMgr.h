#ifndef CONFIGMGR_H
#define CONFIGMGR_H

#include <QObject>
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>
#include <QStandardPaths>
#include <QDir>

// 核心技巧：用inline函数+局部静态变量避免多重定义
class configMgr : public QObject
{
    Q_OBJECT
public:
    // 普通构造函数（非单例）
    explicit configMgr(QObject *parent = nullptr) : QObject(parent) {
        QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir appDataDir(appDataPath);
        if (!appDataDir.exists()) {
            appDataDir.mkpath(".");
        }
        m_configPath = appDataDir.filePath("config.json");
        qDebug()<<"配置缓存地址"<<m_configPath ;
        initConfigFile();
    }

    configMgr(const configMgr&) = delete;
    configMgr& operator=(const configMgr&) = delete;
    ~configMgr() override = default;

    // QML可调用：读取主题配置
    Q_INVOKABLE inline QJsonObject getThemeConfig() {
        QJsonObject config = readConfigFile();
        // 有主题配置则返回，无则返回默认值
        if (config.contains("theme") && config["theme"].isObject()) {
            return config["theme"].toObject();
        } else {
            QJsonObject defaultTheme;
            defaultTheme["opacity"] = 0.9;
            defaultTheme["isDark"] = true;
            defaultTheme["dowloadColor"] = "#00C4B3";
            defaultTheme["globalColor"] = "#00C4B3";
            return defaultTheme;
        }
    }

    // QML可调用：保存主题配置（inline内联，完整参数）
    Q_INVOKABLE inline void saveThemeConfig(double opacity, bool isDark,
                                            const QString& dowloadColor = "#00C4B3",
                                            const QString& globalColor = "#00C4B3") {
        QJsonObject config = readConfigFile();
        QJsonObject themeConfig;
        themeConfig["opacity"] = opacity;
        themeConfig["isDark"] = isDark;
        themeConfig["dowloadColor"] = dowloadColor;
        themeConfig["globalColor"] = globalColor;
        config["theme"] = themeConfig;

        writeConfigFile(config);
    }


private:
    // 初始化配置文件（inline内联）
    inline void initConfigFile() {
        QFile file(m_configPath);
        if (!file.exists()) {
            QJsonObject defaultConfig;
            QJsonObject defaultTheme;
            defaultTheme["opacity"] = 0.9;
            defaultTheme["isDark"] = true;
            defaultTheme["dowloadColor"] = "#00C4B3";
            defaultTheme["globalColor"] = "#00C4B3";
            defaultConfig["theme"] = defaultTheme;

            writeConfigFile(defaultConfig);
        }
    }

    // 读取整个配置文件（inline内联）
    inline QJsonObject readConfigFile() {
        QFile file(m_configPath);
        if (!file.open(QIODevice::ReadOnly)) {
            return QJsonObject(); // 读取失败返回空对象
        }

        QByteArray data = file.readAll();
        file.close();

        QJsonDocument doc = QJsonDocument::fromJson(data);
        return doc.isObject() ? doc.object() : QJsonObject();
    }

    // 写入整个配置文件（inline内联）
    inline void writeConfigFile(const QJsonObject& obj) {
        QFile file(m_configPath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            return;
        }

        QJsonDocument doc(obj);
        // 格式化JSON输出，方便手动编辑
        file.write(doc.toJson(QJsonDocument::Indented));
        file.close();
    }

    // 配置文件路径（成员变量，无静态变量→无多重定义）
    QString m_configPath;
};

#endif // CONFIGMGR_H
