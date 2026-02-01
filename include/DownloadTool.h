#pragma once

#include <QObject>        // QObject类是Qt对象模型的核心
#include <QUrl>           // QUrl类提供了使用URL的便捷接口
#include <QFile>          // QFile类用于对文件进行读写操作
#include <QDir>           // QDir类用于操作路径名及底层文件系统
#include <QPointer>       // QPointer指针引用的对象被销毁时候,会自动指向NULL,解决指针悬挂问题
#include <QCoreApplication>
#include <QNetworkReply>  // QNetworkReply类封装了使用QNetworkAccessManager发布的请求相关的回复信息。
#include <QNetworkAccessManager>  // QNetworkAccessManager类为应用提供发送网络请求和接收答复的API接口
#include <memory>         // 使用std::unique_ptr需要包含该头文件
#include <QRegularExpression>
//#define DOWNLOAD_DEBUG    // 是否打印输出

class DownloadTool : public QObject  // 继承QObject
{
    Q_OBJECT              // 加入此宏，才能使用QT中的signal和slot机制

public:
    // 构造函数参数:  1)http文件完整的url  2)保存的路径
    explicit DownloadTool(const QString& downloadUrl, const QString& savePath,bool dowloadM3u8 = false ,QObject* parent = nullptr);
    ~DownloadTool();

    void startDownload();  // 强制，下载文件
    void cancelDownload(); // 取消下载文件

    void startDownloadM3u8();//下载m3u8文件，合并ts流

signals:
    void sigProgress(qint64 bytesRead, qint64 totalBytes, qreal progress);  // 下载进度信号
    void sigDownloadFinished(QString msg);  // 下载完成信号,取消成功 下载成功
    void sigCandelDownload();
    void M3u8Content(QString content);

private slots:
    void httpFinished();    // QNetworkReply::finished对应的槽函数
    void httpReadyRead();   // QIODevice::readyRead对应的槽函数

    void networkReplyProgress(qint64 bytesRead, qint64 totalBytes);  // QNetworkReply::downloadProgress对应的槽函数

private:
    void startRequest(const QUrl& requestedUrl);
    std::unique_ptr<QFile> openFileForWrite(const QString& fileName);

private:
    QString m_downloadUrl;  // 保存构造时传入的下载url
    QString m_savePath;     // 保存构造时传入的保存路径
    bool dowloadM3u8_;//是否下载m3u8文件，默认false
    const QString defaultFileName = "tmp";  // 默认下载到tmp文件夹
    QUrl url;
    QNetworkAccessManager qnam;
    QPointer<QNetworkReply> reply;
    std::unique_ptr<QFile> file;
    bool httpRequestAborted;
};
