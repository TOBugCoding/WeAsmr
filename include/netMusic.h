#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QList>
#include <QString>
#include <qfile.h>
#include <mutex>
#define COLLECTION_JSON_PATH "./audio_collections.json"

struct AsmrItem {
    Q_GADGET
        Q_PROPERTY(QString name MEMBER name)  // 可选：暴露属性供元对象系统使用
        Q_PROPERTY(bool isDir MEMBER isDir)
public:
    QString name;
    bool isDir;
    AsmrItem(const QString& n = "", bool d = false)
        : name(n), isDir(d) {
    }
};

class NetMusic : public QObject
{
    Q_OBJECT
public:
   
    explicit NetMusic(QObject* parent = nullptr);
    ~NetMusic();
    //多接口调用测试
    //Q_INVOKABLE void net_test(const QString keyword);
    //搜索列表
    Q_INVOKABLE void search_list(const QString keyword);
    //请求播放列表
    Q_INVOKABLE void asmr_list(const QString& path,bool needAdd=true);
    //获取/修改 当前播放路径 不含曲名
    Q_INVOKABLE QString get_path();Q_INVOKABLE void set_path(QString path);
    //获取/修改当前页数
    Q_INVOKABLE int get_page();Q_INVOKABLE void set_page(int page);
    Q_INVOKABLE QString get_collect_file(); Q_INVOKABLE void set_collect_file(QString path);
    //输入完整播放路径 收藏
    //qml播放示例
    //playUrl = "https://mooncdn.asmrmoon.com" + "/" + ASMRPlayer.get_path() +encodeURIComponent(model.name) +"?sign=J6Pg2iI3DmhltIzETpxWUM13oVCCHYw6jHEtlrFKWOE=:0";
    //param:
    //path:所属收藏夹
    //audioName:播放音频的路径，可以是"/" + ASMRPlayer.get_path() +encodeURIComponent(model.name)，播放逻辑可以自己再处理
    Q_INVOKABLE void collect_audio(QString path,QString audioName);
    //加载收藏列表
    //param:
    //path:所属收藏夹
    Q_INVOKABLE void load_audio(QString path);
    //提取所有path键
    Q_INVOKABLE QList<QString> get_all_collections();
    //增加收藏夹 数据保存到json
    Q_INVOKABLE bool add_collection(QString folderName);
    //删除收藏夹
    Q_INVOKABLE bool delete_collection(QString folderName);
    //返回下一个音频路径
    Q_INVOKABLE QString get_audioName();
    //音频名称的 get set
    Q_INVOKABLE QString get_current_playing(); Q_INVOKABLE void set_current_playing(QString path);

    enum netType
    {
        asmr_list_type, search_list_type
    };
signals:
    //load_audio完成后触发信号 发送QList给qml进行加载
    //key:收藏夹名称
    //value:播放音频的路径列表
    void collectCompelet(const QList<QString>& List);
    //asmr搜索更细信号
    void asmrSearchReceived(const QList<AsmrItem>& nameList);
    //asmr节目列表更新信号
    void asmrNamesReceived(const QList<AsmrItem>& nameList);
    //页面更改信号
    void pageChanged(int page);
    //总页数更改信号
    void totalPageChanged(int page);
    //监听收藏夹变更，这2个信号作用是一样的，暂且不管
    void collectChanged();
    void collect_file_changed();
    //当前播放的音频更改
    void current_playing_changed();


private slots:
    //统一返回接口
    void onReplyFinished(QNetworkReply* reply);
    //void onTestReplyFinished(QNetworkReply* reply);
private:
    //检测收藏夹是否存在
    bool isCollectionExist(const QString& folderName, const QJsonArray& collectionArray);
    QNetworkAccessManager* m_netManager;
    QNetworkReply* m_currentReply;
    QNetworkReply* m_preReply;

    //保存播放列表，实现循环播放
    //QList<AsmrItem> audio_list;
    //保存收藏列表的播放列表，实现循环播放
    QList<QString> collect_audio_list;
    QString current_playing;//记录当前正在播放的音频
    QString current_url=""; // 记录完整文件夹路径 不含音频名称
    int current_page=1; //当前的页数
    int total_page=0;
    QString collect_file;//当前的收藏夹

    //区分调用哪个网络接口
    netType replymode = netType::asmr_list_type;
    std::mutex netlock;
    //区分函数调用
    //asmr_list网络回调
    void net_asmr_list(QNetworkReply* m_currentReply);
    //search_list网络回调
    void net_search_list(QNetworkReply* m_currentReply);


};
