#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQmlContext>
#include "CursorPosProvider.h"
#include "netMusic.h"
#include "DownloadToolMgr.h"
int main(int argc, char* argv[])
{

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/fonts/icon.ico"));
    // DownloadTool* dT;
    // dT = new DownloadTool("https://mooncdn.asmrmoon.com/中文音声/婉儿别闹/儿媳的苹果.mp3?sign=J6Pg2iI3DmhltIzETpxWUM13oVCCHYw6jHEtlrFKWOE=:0", QCoreApplication::applicationDirPath() + "/download");
    // dT->startDownload();
    //vlcPlayer.playMedia("https://mooncdn.asmrmoon.com/中文音声/婉儿别闹/儿媳的苹果.mp3?sign=J6Pg2iI3DmhltIzETpxWUM13oVCCHYw6jHEtlrFKWOE=:0");
    DownloadToolMgr dowloadmgr;
    //注册单例，全局调用，避免深度过深导致访问不到
    NetMusic asmr_player;
    qmlRegisterSingletonInstance<NetMusic>(
        "com.asmr.player",  // 模块名
        1, 0,               // 版本号
        "ASMRPlayer",       // QML 中访问的名称
        &asmr_player        // 实例指针
    );

    QQmlApplicationEngine engine;
    CursorPosProvider mousePosProvider;
    engine.rootContext()->setContextProperty("mousePosition", &mousePosProvider);
    engine.rootContext()->setContextProperty("dowloadmgr", &dowloadmgr);
    QUrl url(QString("qrc:/QML/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1); // 加载失败时退出
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
