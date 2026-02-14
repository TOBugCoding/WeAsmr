#include "netMusic.h"

NetMusic::NetMusic(QObject* parent)
    : QObject(parent)
    , m_netManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_preReply(nullptr)
    ,history(nullptr)
{
    // QNetworkProxy proxy;
    // proxy.setType(QNetworkProxy::Socks5Proxy);
    // proxy.setHostName("127.0.0.1");
    // proxy.setPort(3080);                     // 代理端口
    // QNetworkProxy::setApplicationProxy(proxy);
    // 目前用的是Proxifier PE+meriru作为翻墙手段
    history = new QList<FilePath>();
    history->append(FilePath("",1,1));
    connect(m_netManager, &QNetworkAccessManager::finished, this, &NetMusic::onReplyFinished);
}

NetMusic::~NetMusic()
{
    // 析构时停止播放，释放资源
    if (m_currentReply) {
        m_currentReply->disconnect();
        m_currentReply->abort();
        m_currentReply->deleteLater();
    }
    if(history){
        delete history;
        history=nullptr;
    }
}
//发起请求
//接收 任意关键词
void NetMusic::search_list(const QString keyword) {
    //std::unique_lock<std::mutex> lock(netlock);
    replymode = netType::search_list_type;
    QUrl url("https://asmrmoon.com/api/fs/search");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=utf-8");
    request.setHeader(QNetworkRequest::UserAgentHeader,
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");

    QJsonObject params;
    params.insert("parent", "/");
    params.insert("keywords", keyword);
    params.insert("page", current_page);
    params.insert("per_page", 100);
    params.insert("password", "");
    QJsonDocument jsonDoc(params);
    QByteArray postData = jsonDoc.toJson(QJsonDocument::Compact);
    if (m_currentReply) {
        m_preReply = m_currentReply;
        m_preReply->disconnect();
        m_preReply->abort();
        m_preReply->deleteLater();
    }
    m_currentReply = m_netManager->post(request, postData);
    qDebug() << "[ASMR Search Request] 发送请求 - 关键字:" << keyword
        << "POST数据:" << QString(postData);
}
//search_list网络回调
void NetMusic::net_search_list(QNetworkReply* reply) {
    QByteArray responseData = reply->readAll();
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "[ASMR List Error] JSON解析失败:" << parseError.errorString();
        emit errorDetail(parseError.errorString());
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QList<AsmrItem> nameList;
    if (jsonDoc.isObject()) {
        QJsonObject rootObj = jsonDoc.object();
        QJsonObject dataObj = rootObj["data"].toObject();
        QJsonArray contentArray = dataObj["content"].toArray();
        for (const QJsonValue& val : contentArray) {
            if (val.isObject()) {
                QString parent = val.toObject()["parent"].toString();
                QString name = val.toObject()["name"].toString();
                bool isdir = val.toObject()["is_dir"].toBool();
                nameList.append(AsmrItem(parent+"/" + name,isdir));
            }
        }
    }
    emit asmrSearchReceived(nameList);
    if(nameList.size()==0){
        emit errorDetail("暂无搜索结果");
    }
    qDebug() << "\n[搜索结果] 共" << nameList.size() << "个：";
    reply->deleteLater();

}
// 发起请求
// 接收 中文音声/婉儿别闹
// 发送 中文音声/婉儿别闹/  字样，实际请求是/中文音声/婉儿别闹,前面的/由前端添加
void NetMusic::asmr_list(const QString& path,bool needAdd)
{
    //std::unique_lock<std::mutex> lock(netlock);
    replymode = netType::asmr_list_type;
    QString target_path = path;
    current_url = path;
    if (needAdd) {
        current_url +="/";
    }
    qDebug()<<"程序记录路径是"<<current_url;
    QUrl url("https://asmrmoon.com/api/fs/list");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=utf-8");
    request.setHeader(QNetworkRequest::UserAgentHeader,
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");

    QJsonObject params;
    params.insert("path", target_path);
    params.insert("password", "");
    params.insert("page", current_page);
    params.insert("per_page", 20);
    params.insert("refresh", false);

    QJsonDocument jsonDoc(params);
    QByteArray postData = jsonDoc.toJson(QJsonDocument::Compact);

    if (m_currentReply) {
        m_preReply = m_currentReply;
        m_preReply->disconnect();
        m_preReply->abort();
        m_preReply->deleteLater();
    }
    m_currentReply = m_netManager->post(request, postData);
    qDebug() << "[ASMR List Request] 发送请求 - 路径:" << target_path
        << "POST数据:" << QString(postData);
}
//asmr_list网络回调
void NetMusic::net_asmr_list(QNetworkReply* reply) {
    QByteArray responseData = reply->readAll();
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "[ASMR List Error] JSON解析失败:" << parseError.errorString();
        emit errorDetail(parseError.errorString());
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    nameList.clear();
    if (jsonDoc.isObject()) {
        QJsonObject rootObj = jsonDoc.object();
        QJsonObject dataObj = rootObj["data"].toObject();
        total_page = dataObj["total"].toInt() / 20 + (dataObj["total"].toInt() % 20 != 0);
        emit totalPageChanged(total_page);
        QJsonArray contentArray = dataObj["content"].toArray();

        for (const QJsonValue& val : contentArray) {
            if (val.isObject()) {
                QString name = val.toObject()["name"].toString();
                bool isdir= val.toObject()["is_dir"].toBool();
                if (name == "README.md") { continue; }//去除readme文件
                nameList.append(AsmrItem(name, isdir));
            }
        }
    }
    emit asmrNamesReceived(nameList);
    if(nameList.size()==0){
        emit errorDetail("暂无搜索结果");
    }
    qDebug() << "\n[最终提取的所有 name] 共" << nameList.size() << "个：";
    reply->deleteLater();
}

QList<AsmrItem> NetMusic::get_nameList(){

   return nameList;
}

// 回调asmr列表
void NetMusic::onReplyFinished(QNetworkReply* reply)
{
    if (reply != m_currentReply) {
        reply->deleteLater();
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "[ASMR List Error] 请求失败:" << reply->errorString();
        emit errorDetail(reply->errorString());
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    if (replymode == netType::asmr_list_type) {
        net_asmr_list(reply);
    }
    else {
        net_search_list(reply);
    }
    m_currentReply = nullptr;
}

QString NetMusic::get_path() {
    return current_url;
}

void NetMusic::set_path(QString path) {
    current_url = path;
}

int NetMusic::get_page() {
    return current_page;
}

void NetMusic::set_page(int page) {
    if (page <= 0) { return; }
    /*if (page != current_page) {
        current_page = page;
        emit pageChanged(current_page);
    }*/
    current_page = page;
    emit pageChanged(current_page);
}

void NetMusic::collect_audio(QString path, QString audioName) {
    qDebug() << "收藏处理中" << path << audioName;

    // 初始化JSON数据容器
    QJsonArray collectionArray;
    QFile jsonFile(COLLECTION_JSON_PATH);
    bool fileExists = jsonFile.exists();

    // 读取现有JSON文件（如果存在）
    if (fileExists) {
        if (!jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            qWarning() << "无法打开收藏JSON文件：" << jsonFile.errorString();
            return;
        }

        QByteArray jsonData = jsonFile.readAll();
        jsonFile.close();

        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
        if (parseError.error != QJsonParseError::NoError) {
            qWarning() << "JSON解析错误：" << parseError.errorString();
            return;
        }

        if (jsonDoc.isArray()) {
            collectionArray = jsonDoc.array();
        }
        else {
            qWarning() << "JSON格式错误，预期为数组类型";
            return;
        }
    }

    // 查找目标收藏夹（默认收藏夹）
    QJsonObject targetFolder;
    int targetIndex = -1;
    for (int i = 0; i < collectionArray.size(); ++i) {
        QJsonValue itemValue = collectionArray.at(i);
        if (itemValue.isObject()) {
            QJsonObject itemObj = itemValue.toObject();
            if (itemObj["path"].toString() == path) { // 匹配收藏夹名称
                targetFolder = itemObj;
                targetIndex = i;
                break;
            }
        }
    }

    // 处理目标收藏夹（创建/更新）
    QJsonArray audioList;
    int audioCount = 0;

    if (targetIndex != -1) {
        // 存在该收藏夹，读取现有音频列表
        audioList = targetFolder["audio_list"].toArray();
        audioCount = targetFolder["num"].toInt();

        // 检查音频是否已存在（避免重复添加）
        bool isExisted = false;
        for (const QJsonValue& audioVal : audioList) {
            if (audioVal.toString() == audioName) {
                isExisted = true;
                qDebug() << "音频已存在于收藏夹：" << audioName;
                return;
            }
        }

        // 添加新音频路径
        audioList.append(audioName);
        audioCount = audioList.size(); // 更新数量（确保与列表长度一致）
    }
    else {
        // 不存在该收藏夹，创建新条目
        audioList.append(audioName);
        audioCount = 1; // 初始数量为1

        targetFolder["path"] = path;
        targetFolder["audio_list"] = audioList;
        targetFolder["num"] = audioCount;

        // 将新收藏夹添加到数组
        collectionArray.append(targetFolder);
    }

    // 更新现有收藏夹的音频列表和数量（如果是已有收藏夹）
    if (targetIndex != -1) {
        targetFolder["audio_list"] = audioList;
        targetFolder["num"] = audioCount;
        collectionArray.replace(targetIndex, targetFolder);
    }

    // 将更新后的数据写入JSON文件
    QJsonDocument newJsonDoc(collectionArray);
    if (!jsonFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qWarning() << "无法写入收藏JSON文件：" << jsonFile.errorString();
        return;
    }

    // 格式化写入（indent=4 保持可读性，Unicode编码保留中文）
    jsonFile.write(newJsonDoc.toJson(QJsonDocument::Indented));
    jsonFile.close();

    qDebug() << "收藏成功！音频已添加到：" << path << " 总数：" << audioCount;
}

void NetMusic::dislike_collect_audio(QString path, QString audioName) {
    qDebug() << "取消收藏处理中" << path << audioName;

    // 1. 检查文件是否存在（文件不存在则无需取消）
    QFile jsonFile(COLLECTION_JSON_PATH);
    if (!jsonFile.exists()) {
        qWarning() << "收藏文件不存在，无需取消收藏";
        return;
    }

    // 2. 读取并解析现有JSON文件
    if (!jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "无法打开收藏JSON文件：" << jsonFile.errorString();
        return;
    }

    QByteArray jsonData = jsonFile.readAll();
    jsonFile.close();

    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON解析错误：" << parseError.errorString();
        return;
    }

    if (!jsonDoc.isArray()) {
        qWarning() << "JSON格式错误，预期为数组类型";
        return;
    }

    QJsonArray collectionArray = jsonDoc.array();
    bool isModified = false; // 标记是否修改了数据
    int targetIndex = -1;
    QJsonObject targetFolder;

    // 3. 查找目标收藏夹
    for (int i = 0; i < collectionArray.size(); ++i) {
        QJsonValue itemValue = collectionArray.at(i);
        if (itemValue.isObject()) {
            QJsonObject itemObj = itemValue.toObject();
            if (itemObj["path"].toString() == path) { // 匹配收藏夹名称
                targetFolder = itemObj;
                targetIndex = i;
                break;
            }
        }
    }

    // 4. 收藏夹不存在，无需取消
    if (targetIndex == -1) {
        qDebug() << "目标收藏夹不存在：" << path;
        return;
    }

    // 5. 读取收藏夹中的音频列表并移除目标音频
    QJsonArray audioList = targetFolder["audio_list"].toArray();
    QJsonArray newAudioList; // 存储移除后的音频列表

    for (const QJsonValue& audioVal : audioList) {
        // 跳过要取消收藏的音频，其余保留
        if (audioVal.toString() != audioName) {
            newAudioList.append(audioVal);
        } else {
            isModified = true; // 标记数据已修改
            qDebug() << "找到并移除音频：" << audioName;
        }
    }

    // 6. 音频不存在于该收藏夹，无需更新
    if (!isModified) {
        qDebug() << "音频不存在于该收藏夹，无需取消：" << audioName;
        return;
    }

    // 7. 更新收藏夹的音频列表和数量
    targetFolder["audio_list"] = newAudioList;
    targetFolder["num"] = newAudioList.size(); // 同步更新数量

    // 8. 如果收藏夹中已无音频，直接移除该收藏夹；否则更新收藏夹数据
    if (newAudioList.isEmpty()) {
        collectionArray.removeAt(targetIndex);
        qDebug() << "收藏夹已无音频，移除该收藏夹：" << path;
    } else {
        collectionArray.replace(targetIndex, targetFolder);
    }

    // 9. 将更新后的数据写入JSON文件
    QJsonDocument newJsonDoc(collectionArray);
    if (!jsonFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qWarning() << "无法写入收藏JSON文件：" << jsonFile.errorString();
        return;
    }

    // 保持和收藏方法一致的格式化风格（缩进4，保留中文）
    jsonFile.write(newJsonDoc.toJson(QJsonDocument::Indented));
    jsonFile.close();

    qDebug() << "取消收藏成功！收藏夹：" << path << " 剩余音频数：" << newAudioList.size();
}

void NetMusic::load_audio(QString path)
{
    qDebug() << "加载收藏夹音频：" << path;

    // 初始化空列表（兜底）
    QList<QString> audioList;

    // 检查JSON文件是否存在
    QFile jsonFile(COLLECTION_JSON_PATH);
    if (!jsonFile.exists()) {
        qWarning() << "收藏JSON文件不存在：" << COLLECTION_JSON_PATH;
        emit collectCompelet(audioList); // 发送空列表
        return;
    }

    // 打开并读取JSON文件
    if (!jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "无法打开收藏JSON文件：" << jsonFile.errorString();
        emit collectCompelet(audioList);
        return;
    }

    QByteArray jsonData = jsonFile.readAll();
    jsonFile.close();

    // 解析JSON数据
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON解析错误：" << parseError.errorString();
        emit collectCompelet(audioList);
        return;
    }

    if (!jsonDoc.isArray()) {
        qWarning() << "JSON格式错误，预期为数组类型";
        emit collectCompelet(audioList);
        return;
    }

    // 遍历收藏夹数组，查找目标收藏夹
    QJsonArray collectionArray = jsonDoc.array();
    for (const QJsonValue& itemValue : collectionArray) {
        if (!itemValue.isObject()) {
            continue;
        }

        QJsonObject itemObj = itemValue.toObject();
        QString folderPath = itemObj["path"].toString();
        if (folderPath == path) { // 匹配目标收藏夹名称
            // 5. 提取音频列表
            QJsonArray audioJsonArray = itemObj["audio_list"].toArray();
            for (const QJsonValue& audioVal : audioJsonArray) {
                audioList.append(audioVal.toString());
            }
            qDebug() << "成功加载收藏夹[" << path << "]的音频，数量：" << audioList.size();
            break; // 找到目标收藏夹后退出循环
        }
    }

    // 发送加载完成信号（无论是否找到，都发送列表，空列表表示无数据）
    audioList.sort();
    collect_audio_list=audioList;
    //qDebug()<<"列表"<<collect_audio_list;
    emit collectCompelet(audioList);
}

void NetMusic::set_collect_file(QString path,bool fresh) {
    //强制刷新
    if(fresh){
        collect_file = path;
        emit collect_file_changed();
        load_audio(collect_file);
        return;
    }
    if (path != collect_file) {
        collect_file = path;
        emit collect_file_changed();
        load_audio(collect_file);
    }
    
}

QString NetMusic::get_collect_file() {
    return collect_file;
}

QList<QString> NetMusic::get_all_collections()
{
    QList<QString> collectionNames;

    // 1. 检查JSON文件是否存在
    QFile jsonFile(COLLECTION_JSON_PATH);
    if (!jsonFile.exists()) {
        qWarning() << "收藏JSON文件不存在，返回空收藏夹列表";
        // 若文件不存在，返回默认收藏夹（保证基础数据）
        collectionNames << "默认播放列表";
        return collectionNames;
    }

    // 2. 打开并读取JSON文件
    if (!jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "无法打开收藏JSON文件：" << jsonFile.errorString();
        collectionNames << "默认播放列表";
        return collectionNames;
    }

    QByteArray jsonData = jsonFile.readAll();
    jsonFile.close();

    // 3. 解析JSON数据
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON解析错误：" << parseError.errorString();
        collectionNames << "默认播放列表";
        return collectionNames;
    }

    if (!jsonDoc.isArray()) {
        qWarning() << "JSON格式错误，预期为数组类型";
        collectionNames << "默认播放列表";
        return collectionNames;
    }

    // 4. 提取所有收藏夹的path字段
    QJsonArray collectionArray = jsonDoc.array();
    for (const QJsonValue& itemValue : collectionArray) {
        if (itemValue.isObject()) {
            QJsonObject itemObj = itemValue.toObject();
            QString folderName = itemObj["path"].toString().trimmed();
            if (!folderName.isEmpty()) {
                collectionNames << folderName;
            }
        }
    }

    // 5. 兜底：若无任何收藏夹，添加默认收藏夹
    if (collectionNames.isEmpty()) {
        collectionNames << "默认播放列表";
    }

    qDebug() << "获取收藏夹列表成功，数量：" << collectionNames.size() << "列表：" << collectionNames;
    return collectionNames;
}

bool NetMusic::isCollectionExist(const QString& folderName, const QJsonArray& collectionArray)
{
    for (const QJsonValue& itemValue : collectionArray) {
        if (itemValue.isObject()) {
            QJsonObject itemObj = itemValue.toObject();
            if (itemObj["path"].toString().trimmed() == folderName.trimmed()) {
                return true;
            }
        }
    }
    return false;
}

bool NetMusic::add_collection(QString folderName)
{
    // 1. 入参校验：收藏夹名称不能为空
    folderName = folderName.trimmed();
    if (folderName.isEmpty()) {
        qWarning() << "添加收藏夹失败：收藏夹名称不能为空";
        return false;
    }

   
    // 2. 初始化JSON数组（文件不存在则创建空数组）
    QJsonArray collectionArray;
    QFile jsonFile(COLLECTION_JSON_PATH);
    bool fileExists = jsonFile.exists();

    // 3. 读取现有JSON文件（如果存在）
    if (fileExists) {
        if (!jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            qWarning() << "无法打开收藏JSON文件：" << jsonFile.errorString();
            return false;
        }

        QByteArray jsonData = jsonFile.readAll();
        jsonFile.close();

        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
        if (parseError.error != QJsonParseError::NoError) {
            qWarning() << "JSON解析错误：" << parseError.errorString();
            return false;
        }

        if (jsonDoc.isArray()) {
            collectionArray = jsonDoc.array();
        }
        else {
            qWarning() << "JSON格式错误，预期为数组类型，将重置为空数组";
            collectionArray = QJsonArray(); // 格式错误则重置为空数组
        }
    }

    // 4. 检查收藏夹是否已存在（避免重复）
    if (isCollectionExist(folderName, collectionArray)) {
        qWarning() << "添加收藏夹失败：收藏夹[" << folderName << "]已存在";
        return false;
    }

    // 5. 创建新收藏夹对象（空音频列表，num=0）
    QJsonObject newFolderObj;
    newFolderObj["path"] = folderName;          // 收藏夹名称
    newFolderObj["audio_list"] = QJsonArray();  // 空音频列表
    newFolderObj["num"] = 0;                    // 初始音频数量为0

    // 6. 将新收藏夹添加到数组
    collectionArray.append(newFolderObj);

    // 7. 写入更新后的JSON文件
    if (!jsonFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qWarning() << "无法写入收藏JSON文件：" << jsonFile.errorString();
        return false;
    }

    // 格式化写入（保持可读性，保留中文）
    QJsonDocument newJsonDoc(collectionArray);
    jsonFile.write(newJsonDoc.toJson(QJsonDocument::Indented));
    jsonFile.close();

    qDebug() << "收藏夹[" << folderName << "]添加成功";
    emit collectChanged();
    return true;
}

bool NetMusic::delete_collection(QString folderName)
{
    // 入参严格校验
    folderName = folderName.trimmed();
    if (folderName.isEmpty()) {
        qWarning() << "[删除收藏夹] 失败：收藏夹名称为空";
        return false;
    }
    if (folderName == "默认收藏夹") {
        qWarning() << "[删除收藏夹] 失败：禁止删除默认收藏夹";
        return false;
    }
    // 检查文件是否存在
    QFile jsonFile(COLLECTION_JSON_PATH);
    if (!jsonFile.exists()) {
        qWarning() << "[删除收藏夹] 失败：JSON文件不存在，路径：" << COLLECTION_JSON_PATH;
        return false;
    }

    // 读取并解析 JSON 文件
    if (!jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "[删除收藏夹] 失败：无法打开JSON文件，错误：" << jsonFile.errorString();
        return false;
    }

    QByteArray jsonData = jsonFile.readAll();
    jsonFile.close(); // 读取后立即关闭

    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "[删除收藏夹] 失败：JSON解析错误，位置：" << parseError.offset
            << "，错误信息：" << parseError.errorString();
        return false;
    }

    if (!jsonDoc.isArray()) {
        qWarning() << "[删除收藏夹] 失败：JSON根节点不是数组，格式错误";
        return false;
    }

    // 查找并删除目标收藏夹
    QJsonArray collectionArray = jsonDoc.array();
    int targetIndex = -1; // 目标收藏夹在数组中的索引

    // 遍历数组，匹配收藏夹名称（严格匹配）
    for (int i = 0; i < collectionArray.size(); ++i) {
        QJsonValue itemValue = collectionArray.at(i);
        if (!itemValue.isObject()) {
            qWarning() << "[删除收藏夹] 警告：数组项" << i << "不是对象，跳过";
            continue;
        }

        QJsonObject itemObj = itemValue.toObject();
        QString currentFolder = itemObj["path"].toString().trimmed();
        if (currentFolder == folderName) {
            targetIndex = i;
            break; // 找到目标，退出循环
        }
    }

    // 未找到目标收藏夹
    if (targetIndex == -1) {
        qWarning() << "[删除收藏夹] 失败：未找到收藏夹：" << folderName;
        return false;
    }

    // 从数组中移除目标项
    collectionArray.removeAt(targetIndex);
    qDebug() << "[删除收藏夹] 成功找到收藏夹：" << folderName << "，索引：" << targetIndex << "，已从数组移除";

    // 写入修改后的 JSON 数据
    if (!jsonFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qWarning() << "[删除收藏夹] 失败：无法写入JSON文件，错误：" << jsonFile.errorString();
        return false;
    }

    // 重新创建 JsonDocument（关键修复：上一版未更新 doc 导致写入原数据）
    QJsonDocument newJsonDoc(collectionArray);
    // 格式化写入（保留缩进，支持中文，避免乱码）
    QByteArray writeData = newJsonDoc.toJson(QJsonDocument::Indented);
    qint64 writeSize = jsonFile.write(writeData);
    jsonFile.close();

    qInfo() << "[删除收藏夹] 成功：收藏夹" << folderName << "已删除，剩余收藏夹数量：" << collectionArray.size();
    emit collectChanged();
    return true;
}

//void NetMusic::net_test(const QString keyword) {
//    QUrl url("");
//    QNetworkRequest request(url);
//    //立即返回结果，等待信号返回
//    QNetworkReply* reply = m_netManager->get(request);
//    //所以reply指向的内存没有销毁，而是nettest指向完毕后reply这个指针会销毁，所以要用赋值，也可以用=来赋值这个指针，但这个过程中没有复制指针指向的资源？
//    connect(reply, QNetworkReply::finished, this, [=]() {onTestReplyFinished(reply); });
//}
// lambda为每个连接都建立一对一的值返回
//void NetMusic::onTestReplyFinished(QNetworkReply* reply) {
//    QByteArray responseData = reply->readAll();
//    qDebug() << responseData;
//    reply->deleteLater();
//}

//收藏夹列表的顺序播放
QString NetMusic::get_audioName(){
    if(collect_audio_list.length()==0){
        qDebug()<<"播放列表为空";
        return "";
    }
    QString audioName=get_current_playing();
    qDebug()<<"当前播放"<<audioName;
    bool canReturn=false;
    for(QString& child:collect_audio_list){
        if(canReturn){
            qDebug()<<"下一首播放"<<child;
            set_current_playing(child);
            return child;
        }
        if(child.contains(audioName)){
            canReturn=true;
        }

    }
    set_current_playing("");
    return "";

}

void NetMusic::set_current_playing(QString path){
    if(current_playing!=path){
        current_playing=path;
        emit current_playing_changed();
    }
}

QString NetMusic::get_current_playing(){
    return current_playing;
}


void NetMusic::get_sign_path(const QString path){
    //如果路径是含空格的m3u8则不允许进行下一步

    QUrl url("https://asmrmoon.com/api/fs/get");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json;charset=UTF-8");
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36");

    QJsonObject params;
    params.insert("path", path);
    params.insert("password", "");
    QJsonDocument jsonDoc(params);
    QByteArray postData = jsonDoc.toJson(QJsonDocument::Compact);
    QNetworkReply* reply = m_netManager->post(request, postData);

    connect(reply, &QNetworkReply::finished, this, [reply,this,path]() {
        QByteArray responseData = reply->readAll();
        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);
        if (jsonDoc.isObject()) {
            QJsonObject rootObj = jsonDoc.object();
            QJsonObject dataObj = rootObj["data"].toObject();
            QString sign_path=dataObj["raw_url"].toString();
            QStringList parts = sign_path.split("sign=");
            sign_record=parts[1];
            qDebug()<<"路径："<<sign_path;
            if(path.contains(" ")&&path.contains("m3u8")){
                emit emptyM3u8(sign_path);
                qDebug()<<"检测到含空格的m3u8";
                return;
            }else{
                emit signPathReceived(sign_path);
            }

        }
        reply->deleteLater();
    });
}

void NetMusic::download_sign_path(const QString path){

    QUrl url("https://asmrmoon.com/api/fs/get");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json;charset=UTF-8");
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36");

    QJsonObject params;
    params.insert("path", path);
    params.insert("password", "");
    QJsonDocument jsonDoc(params);
    QByteArray postData = jsonDoc.toJson(QJsonDocument::Compact);
    QNetworkReply* reply = m_netManager->post(request, postData);

    connect(reply, &QNetworkReply::finished, this, [reply,this]() {
        QByteArray responseData = reply->readAll();
        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);
        if (jsonDoc.isObject()) {
            QJsonObject rootObj = jsonDoc.object();
            QJsonObject dataObj = rootObj["data"].toObject();
            QString sign_path=dataObj["raw_url"].toString();
            QStringList parts = sign_path.split("sign=");
            sign_record=parts[1];
            emit downloadPathReceived(sign_path);
        }
        reply->deleteLater();
    });
}

QString NetMusic::get_sign_record(){
    return sign_record;
}


void NetMusic::pushHistory(const QString&file,int page,int total){
    if(history){
        if(currentFilePathIndex!=history->size()-1){
            ++currentFilePathIndex;
            history->replace(currentFilePathIndex, FilePath(file,page,total));
            qDebug()<<"添加"<<file<<current_page<<total_page;
        }else{
            history->append(FilePath(file,page,total));
            currentFilePathIndex = history->size() - 1;
            qDebug()<<"添加"<<file<<current_page<<total_page;
        }

    }else{
        qDebug()<<"point empty";
    }
}
void NetMusic::fixHistory(int page){
    FilePath targetItem = history->at(currentFilePathIndex); // 取出当前索引的对象
    targetItem.now_page = page; // 修改页数
    history->replace(currentFilePathIndex, targetItem); // 替换回列表
}
void NetMusic::fixTotalHistory(int totalpage){
    FilePath targetItem = history->at(currentFilePathIndex); // 取出当前索引的对象
    targetItem.total_page = totalpage; // 修改页数
    history->replace(currentFilePathIndex, targetItem); // 替换回列表
}
//回滚历史，有返回
void NetMusic::backHistory(){
    if(currentFilePathIndex!=0){
        --currentFilePathIndex;
        emit sigFilePath(history->at(currentFilePathIndex));
    }

}
//前进历史，有返回
void NetMusic::forwardHistory(){
    if(currentFilePathIndex!=history->size()-1){
        ++currentFilePathIndex;
        emit sigFilePath(history->at(currentFilePathIndex));
    }

}
