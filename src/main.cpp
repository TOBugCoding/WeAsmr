#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQmlContext> 
#include "fpscounter.h"
#include "music.h"
#include "CursorPosProvider.h"
#include "NumberToChinese.h"
#include "DataMgr.h"
#include "TcpClient.h"
#include "netMusic.h"
#include "PageMgr.h"
int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/fonts/icon.ico"));

    qmlRegisterType<AudioMetadata>("AudioMetadata", 1, 0, "AudioMetadata");
    qmlRegisterType<MusicLibrary>("MusicLibrary", 1, 0, "MusicLibrary");
    qmlRegisterType<FpsCounter>("FpsCounter", 1, 0, "FpsCounter");
    qmlRegisterType<NumberToChinese>("Number", 1, 0, "NumberToChinese");
    qmlRegisterType<TcpClient>("TcpClient", 1, 0, "TcpClient");
    //qmlRegisterType<NetMusic>("NetMusic", 1, 0, "NetMusic");
    //注册单例，全局调用，避免深度过深导致访问不到
    NetMusic asmr_player;
    qmlRegisterSingletonInstance<NetMusic>(
        "com.asmr.player",  // 模块名
        1, 0,               // 版本号
        "ASMRPlayer",       // QML 中访问的名称
        &asmr_player        // 实例指针
    );
    qmlRegisterType<PageMgr>("PageMgr", 1, 0, "PageMgr");
    QQmlApplicationEngine engine;
    CursorPosProvider mousePosProvider;
    DataMgr dataMgr;
    engine.rootContext()->setContextProperty("mousePosition", &mousePosProvider);
    engine.rootContext()->setContextProperty("dataMgr", &dataMgr);
    engine.load(QUrl("qrc:/QML/main.qml"));   // 关键：qrc 路径
    QObject* rootObject = engine.rootObjects().first();
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
