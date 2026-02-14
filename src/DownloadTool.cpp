#include "DownloadTool.h"
#include "Downloadm3u8.h"
#include <qthread.h>
DownloadTool::DownloadTool(const QString& downloadUrl, const QString& savePath, bool dowloadM3u8,QObject* parent)
    : QObject(parent)
{
    m_downloadUrl = downloadUrl;
    m_savePath    = savePath;
    dowloadM3u8_= dowloadM3u8;
}

DownloadTool::~DownloadTool() {}

void DownloadTool::startDownload()
{
    const QUrl newUrl = QUrl::fromUserInput(m_downloadUrl);

    if (!newUrl.isValid()) {
        return;
    }

    QString fileName = newUrl.fileName();

    if (fileName.isEmpty()) fileName = defaultFileName;
    if (m_savePath.isEmpty()) { m_savePath = QCoreApplication::applicationDirPath() + "/tmp"; }
    if (!QFileInfo(m_savePath).isDir()) {
        QDir dir;
        dir.mkpath(m_savePath);
    }

    fileName.prepend(m_savePath + '/');
    if (QFile::exists(fileName)) { QFile::remove(fileName); }
    file = openFileForWrite(fileName);
    if (!file) return;

    startRequest(newUrl);
}

void DownloadTool::cancelDownload()
{
    httpRequestAborted = true;
    reply->abort();
    //reply->disconnect(this);
    emit sigCandelDownload();//取消m3u8的下载
}

void DownloadTool::httpFinished()
{
    QFileInfo fi;
    //关闭文件夹，使用fi接管记录文件名
    if (file) {
        fi.setFile(file->fileName());
        file->close();
        file.reset();
    }

    // 中断下载处理
    if (httpRequestAborted) {
        emit sigDownloadFinished("已取消下载");
        return;
    }

    if (reply->error()) {
        emit sigDownloadFinished("下载异常：请求对象已释放");
        return;
    }




    const QVariant redirectionTarget = reply->attribute(QNetworkRequest::RedirectionTargetAttribute);

    if (!redirectionTarget.isNull()) {
        const QUrl redirectedUrl = url.resolved(redirectionTarget.toUrl());
        file = openFileForWrite(fi.absoluteFilePath());
        if (!file) { return; }
        startRequest(redirectedUrl);
        return;
    }
    //判断出是m3u8文件，执行下载而不是在线播放
    if(m_downloadUrl.contains("m3u8")&&!dowloadM3u8_){
        QString m3u8Content;
        //读取m3u8文件的ts视频地址
        if (fi.exists()) {
            QFile m3u8File(fi.absoluteFilePath()); // 用fi的绝对路径打开文件
            if (m3u8File.open(QIODevice::ReadOnly | QIODevice::Text)) {
                m3u8Content = QString::fromUtf8(m3u8File.readAll());
                m3u8File.close();
                qDebug() << "成功读取m3u8文件，内容长度：" << m3u8Content.length(); // 调试：确认读取到内容
            } else {
                qCritical() << "无法读取m3u8文件：" << m3u8File.errorString();
                emit sigDownloadFinished("下载失败");
                return;
            }
        } else {
            qCritical() << "m3u8文件真的不存在！路径：" << fi.absoluteFilePath(); // 调试：打印实际路径
            emit sigDownloadFinished("下载失败");
            return;
        }
        //新建一个下载线程
        QThread* downloadThread = new QThread();
        Downloadm3u8* downloader=new Downloadm3u8();
        emit sigProgress(0, 0, 0.01);
        downloader->moveToThread(downloadThread);
        QObject::connect(this,&DownloadTool::sigCandelDownload,this,[downloader](){
            qInfo() << "cancelDownload信号触发，强制结束合并/下载";
            downloader->stopMerge();//停止成功后触发mergeFinished
        },Qt::QueuedConnection);

        QObject::connect(downloader, &Downloadm3u8::progressUpdated, this, [downloader,this](int current, int total, const QString &url) {
            qInfo() << QString("进度：%1/%2，当前下载：%3").arg(current).arg(total).arg(url);
            qreal progress = qreal(current) / qreal(total);
            emit sigProgress(current, total, progress);
        }, Qt::QueuedConnection);
        QObject::connect(downloader, &Downloadm3u8::errorOccurred, this, [](const QString &errorMsg) {
            qCritical() << "错误：" << errorMsg;
        }, Qt::QueuedConnection);

        //下载结束，执行指针销毁操作
        QObject::connect(downloader, &Downloadm3u8::mergeFinished, this,[fi,downloader,downloadThread,this](bool suc,const QString &Msg) {
            qCritical() <<"下载状态:"<<suc <<"消息："<<"：" << Msg;
            QFile::remove(fi.absoluteFilePath());//删除m3u8文件
            downloader->deleteLater();
            //销毁完成告知Mgr
            QObject::connect(downloadThread,&QThread::finished,this,[this,suc,Msg](){
                qDebug()<<"线程退出";
                if (suc) {
                    emit sigDownloadFinished(Msg);
                } else {
                    emit sigDownloadFinished(Msg);
                }
            },Qt::QueuedConnection);

            downloadThread->quit();
            downloadThread->wait();
            downloadThread->deleteLater();
        },Qt::QueuedConnection);



        //组装最终输出视频地址
        const QUrl newUrl = QUrl::fromUserInput(m_downloadUrl);
        if (!newUrl.isValid()) {
            return;
        }
        QString fileName = newUrl.fileName();
        fileName = fileName.replace(QRegularExpression("\\.m3u8$", QRegularExpression::CaseInsensitiveOption), ".ts");
        fileName.prepend(m_savePath + '/');
        if (QFile::exists(fileName)) { QFile::remove(fileName); }

        //线程启动下载
        QObject::connect(downloadThread, &QThread::started, downloader, [downloader, m3u8Content, fileName]() {
            downloader->startMerge(m3u8Content, fileName);
        }, Qt::DirectConnection);
        downloadThread->start();
    }
    //判断出是m3u8,且存在空格的，需要将ts转义文件喂给播放器
    else if(m_downloadUrl.contains("m3u8")){
        QString m3u8Content;
        if (fi.exists()) {
            QFile m3u8File(fi.absoluteFilePath());
            if (m3u8File.open(QIODevice::ReadOnly | QIODevice::Text)) {
                m3u8Content = QString::fromUtf8(m3u8File.readAll());
                m3u8File.close();
                QStringList m3u8Lines = m3u8Content.split(QRegularExpression("[\r\n]"), Qt::SkipEmptyParts);
                QStringList newM3u8Lines;
                for (const QString& line : m3u8Lines) {
                    QString trimmedLine = line.trimmed();
                    // 注释行/空行直接保留，不处理
                    if (trimmedLine.startsWith("#") || trimmedLine.isEmpty()) {
                        newM3u8Lines << line;
                    } else {
                        // 核心逻辑：按/拆分路径分段，避免层级破坏
                        QStringList pathSegments = trimmedLine.split("/");
                        QStringList handledSegments;
                        for (const QString& segment : pathSegments) {
                            QString handledSegment = segment; // 先创建副本，避免修改原始segment
                            handledSegment.replace(" ", "%20"); // 对副本原地替换，仅改空格
                            handledSegments << handledSegment;
                        }
                        // 用原始/拼接分段，还原合法的相对路径
                        QString finalTsUrl = handledSegments.join("/");
                        newM3u8Lines << finalTsUrl;
                    }
                }
                // 重构转义后的m3u8内容
                m3u8Content = newM3u8Lines.join("\n");

                // 将仅替换空格后的内容写回本地m3u8文件（覆盖原有内容）
                if (m3u8File.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
                    m3u8File.write(m3u8Content.toUtf8()); // 保持UTF-8编码，避免乱码
                    m3u8File.close();
                    qDebug() << "成功写回m3u8文件，仅将空格替换为%20";
                } else {
                    qCritical() << "无法写入m3u8文件：" << m3u8File.errorString();
                    emit sigDownloadFinished("m3u8文件处理失败");
                    return;
                }

                // 规范VLC播放路径：解码原始路径+添加file:///前缀（本地文件专用）
                QString originalPath = QUrl::fromPercentEncoding(fi.absoluteFilePath().toUtf8());
                QString vlcPlayPath = "file:///" + originalPath;
                emit M3u8Content(vlcPlayPath); // 发射给VLC的合法播放路径
                emit sigDownloadFinished("下载完成");

            } else {
                qCritical() << "无法读取m3u8文件：" << m3u8File.errorString();
                emit sigDownloadFinished("下载失败");
                return;
            }
        } else {
            qCritical() << "m3u8文件不存在！路径：" << fi.absoluteFilePath();
            emit sigDownloadFinished("下载失败");
            return;
        }
    }
    else{
        emit sigDownloadFinished("下载完成");
    }

}

//数据准备好保存到file文件中
void DownloadTool::httpReadyRead()
{
    if (file) file->write(reply->readAll());
}

void DownloadTool::networkReplyProgress(qint64 bytesRead, qint64 totalBytes)
{
    qreal progress = qreal(bytesRead) / qreal(totalBytes);
    emit sigProgress(bytesRead, totalBytes, progress);
}

void DownloadTool::startRequest(const QUrl& requestedUrl)
{
    url = requestedUrl;
    httpRequestAborted = false;

    reply = qnam.get(QNetworkRequest(url));
    connect(reply, &QNetworkReply::finished, this, &DownloadTool::httpFinished);
    connect(reply, &QIODevice::readyRead, this, &DownloadTool::httpReadyRead);
    connect(reply, &QNetworkReply::downloadProgress, this, &DownloadTool::networkReplyProgress);

}

std::unique_ptr<QFile> DownloadTool::openFileForWrite(const QString& fileName)
{
    std::unique_ptr<QFile> file(new QFile(fileName));
    if (!file->open(QIODevice::WriteOnly)) {
        return nullptr;
    }
    return file;
}

void DownloadTool::startDownloadM3u8(){}
