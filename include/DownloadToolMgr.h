#ifndef DOWNLOADTOOLMGR_H
#define DOWNLOADTOOLMGR_H

#include <QObject>
#include <QVector>
#include <QMap>
#include <QUrl>
#include <QString>
#include <QRegularExpression> // 新增：正则匹配更精准
#include "DownloadTool.h"
#include <QCoreApplication>

class DownloadToolMgr:public QObject {
    Q_OBJECT
public:

    explicit DownloadToolMgr(QObject* parent = nullptr){}

    Q_INVOKABLE void addDownloadTask(const QString& fullUrl){
        QString corePath = extractCorePathFromUrl(fullUrl);
        if (corePath.isEmpty()) {
            qWarning() << "解析下载URL失败：" << fullUrl;
            return;
        }

        if (isTaskExists(corePath)) {
            emit sendMsg(corePath);
            return;
        }

        DowloadItem* item = new DowloadItem(corePath,fullUrl);
        DowloadContainer.push_back(item);

        // 连接进度信号
        connect(&item->tool, &DownloadTool::sigProgress, this, [this, corePath](qint64 bytesRead, qint64 totalBytes, qreal progress) {
            m_corePathProgressMap[corePath] = progress;
            emit downloadProgressUpdated(corePath, progress);
            //qDebug()<<corePath<<"receive dowload signal"<<QString::number(progress * 100, 'f', 2) << "%    ";
            if(progress==1){
                emit downloadFinished(corePath);
            }
        });

        connect(&item->tool, &DownloadTool::sigDownloadFinished,this,[this,corePath](){
            //下载完成清空
            qDebug()<<"dowloadFinished"<<corePath;
            candelDownload(corePath);
        });
        item->tool.startDownload();
    }

    Q_INVOKABLE void candelDownload(const QString& targetCorePath){
        for (auto it = DowloadContainer.constBegin(); it != DowloadContainer.constEnd(); ++it) {
            DowloadItem* p = *it;
            // 精准匹配核心路径
            if (p->corePath == targetCorePath) {
                p->tool.cancelDownload();
                m_corePathProgressMap.remove(p->corePath);
                emit downloadProgressUpdated(p->corePath, 0.0);
                DowloadContainer.erase(it);
                delete p;
                return;
            }
        }
    }

    Q_INVOKABLE qreal getDownloadProgress(const QString& targetCorePath) {
        // 精准匹配核心路径
        if (m_corePathProgressMap.contains(targetCorePath)) {
            return m_corePathProgressMap[targetCorePath];
        }
        return 0.0;
    }
    QString extractCorePathFromUrl(const QString& fullUrl) {
        const QString fixedPrefix = "https://mooncdn.asmrmoon.com";
        const QString signParamFlag = "?sign=";

        QString path = fullUrl;
        // 1. 移除固定前缀
        if (path.startsWith(fixedPrefix)) {
            path = path.mid(fixedPrefix.length());
        }

        // 2. 移除sign参数
        int signIndex = path.indexOf(signParamFlag);
        if (signIndex != -1) {
            path = path.left(signIndex);
        }

        // 3. URL解码：将%XX格式转为原始中文
        path = QUrl::fromPercentEncoding(path.toUtf8());

        // 4. 格式统一
        path = path.trimmed();
        path = path.remove(QRegularExpression("^/+|/+$"));
        if (!path.isEmpty() && !path.startsWith("/")) {
            path = "/" + path;
        }

        return path;
    }

signals:
    void downloadProgressUpdated(const QString& corePath, qreal progress);
    void downloadFinished(const QString& corePath);
    void sendMsg(const QString&msg);
private:
    // 核心工具函数：基于固定规则截取核心路径


    // 检查任务是否存在（精准匹配核心路径）
    bool isTaskExists(const QString& corePath) {
        // 1. 查进度映射表
        if (m_corePathProgressMap.contains(corePath)) {
            return true;
        }
        // 2. 查任务容器
        for (DowloadItem* item : DowloadContainer) {
            if (item->corePath == corePath) {
                return true;
            }
        }
        return false;
    }

    struct DowloadItem{
        QString corePath;      // 核心路径：/中文音声/婉儿别闹/儿媳的苹果.mp3
        DownloadTool tool;
        DowloadItem(const QString corepath="",const QString fullUrl="")
            :corePath(corepath),
            tool(fullUrl, QCoreApplication::applicationDirPath() + "/download") {
        }
    };

private:
    QVector<DowloadItem*> DowloadContainer;
    QMap<QString, qreal> m_corePathProgressMap; // key：核心路径（如/中文音声/婉儿别闹/儿媳的苹果.mp3）
};

#endif // DOWNLOADTOOLMGR_H
