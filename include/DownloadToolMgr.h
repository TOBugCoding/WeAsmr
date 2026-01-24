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
    //这里可以自己判断是否存在相同的文件名，一旦存在，就将fullUrl先传递给前端，确定后直接执行
    //downloadDirect
    Q_INVOKABLE void addDownloadTask(const QString& fullUrl,bool downloadDirect=false){
        //默认需要检查文件是否存在相同的，注意，这里判断的是前缀，因为m3u8对应的是ts
        QString corePath = extractCorePathFromUrl(fullUrl);
        if (corePath.isEmpty()) {
            qWarning() << "解析下载URL失败：" << fullUrl;
            return;
        }
        if (isTaskExists(corePath)) {
            emit sendMsg("该下载任务已存在");
            return;
        }
        if(!downloadDirect){
            const QUrl newUrl = QUrl::fromUserInput(fullUrl);
            if (!newUrl.isValid()) {
                return;
            }
            QString fileName = newUrl.fileName();
            QString downloadDir = QCoreApplication::applicationDirPath() + "/download/";
            QString fullFilePath = downloadDir + fileName;

            // 调用自定义函数，判断是否存在同名（忽略后缀）的文件
            if (isSameFileNameExists(downloadDir, fileName)) {
                emit exitFile(corePath);
                return;
            }
        }
        DowloadItem* item = new DowloadItem(corePath,fullUrl);
        DowloadContainer.push_back(item);

        // 连接进度信号
        connect(&item->tool, &DownloadTool::sigProgress, this, [this, corePath](qint64 bytesRead, qint64 totalBytes, qreal progress) {
            m_corePathProgressMap[corePath] = progress;
            emit downloadProgressUpdated(corePath, progress);
            //qDebug()<<corePath<<"receive dowload signal"<<QString::number(progress * 100, 'f', 2) << "%    ";
        });

        connect(&item->tool, &DownloadTool::sigDownloadFinished,this,[this,corePath](QString msg){
            //下载完成清空
            qDebug()<<"dowloadFinished"<<corePath;
            downloadFinishedClear(corePath);//清空下载任务占用的内存
            emit downloadFinished(msg,corePath);//发送qml端进行提示
        });
        item->tool.startDownload();
    }

    Q_INVOKABLE void candelDownload(const QString& targetCorePath){
        for (auto it = DowloadContainer.constBegin(); it != DowloadContainer.constEnd(); ++it) {
            DowloadItem* p = *it;
            // 精准匹配核心路径
            if (p->corePath == targetCorePath) {
                //取消下载仅对 对象进行告知，对象处理完成后返回sigDownloadFinished
                p->tool.cancelDownload();
                emit downloadProgressUpdated(p->corePath, 0.0);
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
        // 移除固定前缀
        if (path.startsWith(fixedPrefix)) {
            path = path.mid(fixedPrefix.length());
        }

        // 移除sign参数
        int signIndex = path.indexOf(signParamFlag);
        if (signIndex != -1) {
            path = path.left(signIndex);
        }

        // URL解码：将%XX格式转为原始中文
        path = QUrl::fromPercentEncoding(path.toUtf8());

        // 格式统一
        path = path.trimmed();
        path = path.remove(QRegularExpression("^/+|/+$"));
        if (!path.isEmpty() && !path.startsWith("/")) {
            path = "/" + path;
        }

        return path;
    }

signals:
    void downloadProgressUpdated(const QString& corePath, qreal progress);
    void downloadFinished(const QString& msg,const QString& corePath);
    void sendMsg(const QString&msg);
    void exitFile(const QString& fullUrl);
private:
    // 核心工具函数：基于固定规则截取核心路径
    //下载完成释放内存
    void downloadFinishedClear(const QString& targetCorePath){
        for (auto it = DowloadContainer.constBegin(); it != DowloadContainer.constEnd(); ++it) {
            DowloadItem* p = *it;
            // 精准匹配核心路径
            if (p->corePath == targetCorePath) {
                m_corePathProgressMap.remove(p->corePath);
                emit downloadProgressUpdated(p->corePath, 0.0);
                DowloadContainer.erase(it);
                delete p;
                return;
            }
        }
    }
    // 检查任务是否存在（精准匹配核心路径）
    bool isTaskExists(const QString& corePath) {
        // 查进度映射表
        if (m_corePathProgressMap.contains(corePath)) {
            return true;
        }
        // 查任务容器
        for (DowloadItem* item : DowloadContainer) {
            if (item->corePath == corePath) {
                return true;
            }
        }
        return false;
    }
    // 自定义函数：判断目录下是否存在同名（忽略后缀）的文件
    bool isSameFileNameExists(const QString& dirPath, const QString& targetFileName) {
        // 提取目标文件名的“无后缀部分”
        QString targetBaseName = QFileInfo(targetFileName).baseName();

        QDir dir(dirPath);
        // 过滤出目录下的所有文件（排除文件夹）
        QStringList filters;
        filters << "*.*"; // 匹配所有带后缀的文件
        QFileInfoList fileList = dir.entryInfoList(filters, QDir::Files);

        // 遍历所有文件，对比无后缀名称
        for (const QFileInfo& fileInfo : fileList) {
            if (fileInfo.baseName() == targetBaseName) {
                return true; // 找到同名（忽略后缀）的文件
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
