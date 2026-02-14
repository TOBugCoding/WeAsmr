#ifndef DOWNLOADM3U8_H
#define DOWNLOADM3U8_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QFile>
#include <QStringList>
#include <QUrl>
#include <QDir>
#include <QPointer>
#include <QCoreApplication>
#include <QNetworkReply>
#include <QMap>
#include <QMutex>
#include <QWaitCondition>
#include <QAtomicInt>

// M3U8下载合并类（并发优化版）
class Downloadm3u8 : public QObject
{
    Q_OBJECT
public:
    explicit Downloadm3u8(QObject *parent = nullptr);
    ~Downloadm3u8() override;

    /**
     * @brief 设置最大并发下载数（默认8）
     * @param maxConcurrent 最大并发数（建议4-16）
     */
    void setMaxConcurrent(int maxConcurrent);

    /**
     * @brief 启动M3U8下载合并
     * @param m3u8Content M3U8文件的文本内容
     * @param outputTsPath 合并后的TS文件保存路径
     */
    void startMerge(const QString &m3u8Content, const QString &outputTsPath);

    /**
     * @brief 停止下载合并
     */
    void extracted();
    void stopMerge();
    
    
signals:
    // 进度更新（current:已完成分片数, total:总分片数）
    void progressUpdated(int current, int total, const QString &currentUrl = "");
    // 合并完成
    void mergeFinished(bool success, const QString &outputPath = "");
    // 错误信息
    void errorOccurred(const QString &errorMsg);

private slots:
    // 单个TS分片下载完成
    void onReplyFinished(QNetworkReply *reply);

private:
    // 解析M3U8内容
    void parseM3U8(const QString &m3u8Content);
    // 启动下一批下载任务（控制并发）
    void startNextDownloads();
    // 合并所有缓存的TS分片
    bool mergeCacheFiles();
    // 中途合并
    void partCacheFiles();
    // 清理资源（缓存文件、网络请求等）
    void cleanResources();
    // 获取分片的缓存文件路径
    QString getCacheFilePath(int index);

private:
    QNetworkAccessManager *m_nam;              // 网络请求管理器
    QString m_outputTsPath;                   // 最终TS文件路径
    QString m_cacheDir;                       // 分片缓存目录
    QStringList m_tsUrlList;                  // TS分片URL列表
    QAtomicInt m_currentDownloaded;           // 已完成下载的分片数
    QAtomicInt m_currentProcessing;           // 正在下载的分片数
    int m_maxConcurrent;                      // 最大并发数
    bool m_isStopped;                         // 是否手动停止
    bool m_isMerging;                         // 是否正在合并
    QMutex m_mutex;                           // 线程安全锁
    QMap<int, QPointer<QNetworkReply>> m_runningReplies; // 运行中的请求
};

#endif // DOWNLOADM3U8_H
