#include "Downloadm3u8.h"
#include <QNetworkRequest>
#include <QTextStream>
#include <QRegularExpression>
#include <QDebug>
#include <QStandardPaths>
#include <QUuid>
#include <QFileInfo>

Downloadm3u8::Downloadm3u8(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_currentDownloaded(0)
    , m_currentProcessing(0)
    , m_maxConcurrent(8)  // 默认最大并发8个
    , m_isStopped(false)
    , m_isMerging(false)
{
    connect(m_nam, &QNetworkAccessManager::finished, this, &Downloadm3u8::onReplyFinished);

    // 创建临时缓存目录（基于应用缓存+唯一ID）
    QString tempCache = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    m_cacheDir = tempCache + "/m3u8_cache_" + QUuid::createUuid().toString(QUuid::WithoutBraces);
    QDir().mkpath(m_cacheDir); // 确保目录存在
    qDebug()<<"缓存目录"<<m_cacheDir;
}

Downloadm3u8::~Downloadm3u8()
{
    stopMerge();
}

void Downloadm3u8::setMaxConcurrent(int maxConcurrent)
{
    QMutexLocker locker(&m_mutex);
    if (maxConcurrent > 0 && maxConcurrent <= 32) { // 限制最大并发不超过32
        m_maxConcurrent = maxConcurrent;
    }
}

void Downloadm3u8::startMerge(const QString &m3u8Content, const QString &outputTsPath)
{
    QMutexLocker locker(&m_mutex);

    // 重置状态
    m_isStopped = false;
    m_isMerging = false;
    m_currentDownloaded = 0;
    m_currentProcessing = 0;
    m_tsUrlList.clear();
    m_runningReplies.clear();
    m_outputTsPath = outputTsPath;

    // 解析M3U8
    parseM3U8(m3u8Content);
    if (m_tsUrlList.isEmpty()) {
        QString errorMsg = "解析M3U8失败：未找到有效的TS分片链接";
        emit errorOccurred(errorMsg);
        emit mergeFinished(false, "");
        return;
    }

    qDebug() << QString("开始并发下载，总分片数：%1，最大并发：%2").arg(m_tsUrlList.size()).arg(m_maxConcurrent);

    // 启动第一批下载任务
    startNextDownloads();
}

void Downloadm3u8::stopMerge()
{
    QMutexLocker locker(&m_mutex);
    m_isStopped = true;

    // 取消所有正在运行的请求
    for (QNetworkReply *reply : m_runningReplies) {
        if (reply && !reply->isFinished()) {
            reply->abort();
        }
    }
    m_runningReplies.clear();

    // 清理缓存目录
    QDir cacheDir(m_cacheDir);
    if (cacheDir.exists()) {
        cacheDir.removeRecursively();
    }
    emit mergeFinished(false, m_outputTsPath);
}

void Downloadm3u8::onReplyFinished(QNetworkReply *reply)
{
    QMutexLocker locker(&m_mutex);

    // 移除运行中的请求记录
    int index = m_runningReplies.key(reply, -1);
    if (index != -1) {
        m_runningReplies.remove(index);
    }

    // 处理停止状态
    if (m_isStopped) {
        reply->deleteLater();
        return;
    }

    // 处理下载错误
    if (reply->error() != QNetworkReply::NoError) {
        QString errorMsg = QString("分片%1下载失败：%2").arg(index).arg(reply->errorString());
        emit errorOccurred(errorMsg);
        cleanResources();
        emit mergeFinished(false, m_outputTsPath);
        reply->deleteLater();
        return;
    }

    // 保存分片到缓存文件
    QString cacheFile = getCacheFilePath(index);
    QFile file(cacheFile);
    if (!file.open(QIODevice::WriteOnly)) {
        QString errorMsg = QString("分片%1缓存失败：无法打开文件 %2").arg(index).arg(cacheFile);
        emit errorOccurred(errorMsg);
        cleanResources();
        emit mergeFinished(false, m_outputTsPath);
        reply->deleteLater();
        return;
    }

    // 写入分片数据
    QByteArray tsData = reply->readAll();
    qint64 written = file.write(tsData);
    file.close();

    if (written != tsData.size()) {
        QString errorMsg = QString("分片%1缓存失败：写入数据不完整").arg(index);
        emit errorOccurred(errorMsg);
        cleanResources();
        emit mergeFinished(false, m_outputTsPath);
        reply->deleteLater();
        return;
    }

    // 更新进度
    m_currentDownloaded++;
    emit progressUpdated(m_currentDownloaded, m_tsUrlList.size(), reply->url().toString());

    // 启动下一个下载任务
    startNextDownloads();

    // 所有分片下载完成，开始合并
    if (m_currentDownloaded >= m_tsUrlList.size() && !m_isMerging) {
        qDebug()<<"所有分片下载完成，开始合并";
        m_isMerging = true;
        bool mergeSuccess = mergeCacheFiles();
        cleanResources();//合并完成，删除缓存
        qDebug()<<"合并是否完成"<<mergeSuccess;

        if (mergeSuccess) {
            qDebug() << QString("合并完成！目标文件：%1").arg(m_outputTsPath);
        } else {
            emit errorOccurred("分片合并失败");
        }
        emit mergeFinished(true, m_outputTsPath);
    }

    reply->deleteLater();
}

void Downloadm3u8::startNextDownloads()
{
    if (m_isStopped || m_isMerging) {
        return;
    }

    // 计算可启动的新任务数
    int availableSlots = m_maxConcurrent - m_runningReplies.size();
    if (availableSlots <= 0) {
        return;
    }

    // 找到下一个未下载的分片索引
    int nextIndex = m_currentDownloaded + m_runningReplies.size();
    while (availableSlots > 0 && nextIndex < m_tsUrlList.size()) {
        // 启动下载
        QString tsUrl = m_tsUrlList.at(nextIndex);

        QNetworkReply *reply = m_nam->get(QNetworkRequest(tsUrl));
        m_runningReplies.insert(nextIndex, reply);

        nextIndex++;
        availableSlots--;
        m_currentProcessing++;
    }
}

bool Downloadm3u8::mergeCacheFiles()
{
    // 打开最终文件
    QFile outputFile(m_outputTsPath);
    if (!outputFile.open(QIODevice::WriteOnly)) {
        qDebug() << "无法打开输出文件：" << outputFile.errorString();
        return false;
    }

    // 按顺序合并所有缓存分片
    for (int i = 0; i < m_tsUrlList.size(); i++) {
        QString cacheFile = getCacheFilePath(i);
        QFile inputFile(cacheFile);
        if (!inputFile.open(QIODevice::ReadOnly)) {
            qDebug() << "无法读取缓存文件：" << cacheFile;
            outputFile.close();
            return false;
        }

        // 分片数据写入最终文件
        QByteArray data = inputFile.readAll();
        if (outputFile.write(data) != data.size()) {
            qDebug() << "写入分片" << i << "失败";
            inputFile.close();
            outputFile.close();
            return false;
        }

        inputFile.close();
        QFile::remove(cacheFile); // 删除临时缓存文件
    }
    outputFile.flush();
    outputFile.close();


    return true;
}

void Downloadm3u8::parseM3U8(const QString &m3u8Content)
{
    m_tsUrlList.clear();

    QStringList lines = m3u8Content.split(QRegularExpression(R"(\r?\n)"), Qt::SkipEmptyParts);
    QRegularExpression tsRegex(R"(^https?://.+\.ts$)", QRegularExpression::CaseInsensitiveOption);

    foreach (QString line, lines) {
        line = line.trimmed();
        if (!line.startsWith("#") && tsRegex.match(line).hasMatch()) {
            m_tsUrlList.append(line);
        }
    }
}

//清理所有缓存资源
void Downloadm3u8::cleanResources()
{
    // 关闭并清理缓存目录
    QDir cacheDir(m_cacheDir);
    if (cacheDir.exists()) {
        cacheDir.removeRecursively();
    }

    // 重置状态
    m_tsUrlList.clear();
    m_runningReplies.clear();
    m_currentDownloaded = 0;
    m_currentProcessing = 0;
    m_isMerging = false;
}

QString Downloadm3u8::getCacheFilePath(int index)
{
    // 生成唯一的缓存文件名（按索引命名，保证顺序）
    return QString("%1/ts_%2.cache").arg(m_cacheDir).arg(index, 6, 10, QChar('0'));
}
