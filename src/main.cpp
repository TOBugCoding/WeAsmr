#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQmlContext> 
#include "fpscounter.h"
#include "CursorPosProvider.h"
#include "netMusic.h"
//#include "logger.h"
//#include "NumberToChinese.h"
//#include "TcpClient.h"
//#include "PageMgr.h"
int main(int argc, char* argv[])
{
    //logger log;


    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/fonts/icon.ico"));

    qmlRegisterType<FpsCounter>("FpsCounter", 1, 0, "FpsCounter");
    //qmlRegisterType<NumberToChinese>("Number", 1, 0, "NumberToChinese");
    //qmlRegisterType<TcpClient>("TcpClient", 1, 0, "TcpClient");
    //qmlRegisterType<NetMusic>("NetMusic", 1, 0, "NetMusic");
    //注册单例，全局调用，避免深度过深导致访问不到
    NetMusic asmr_player;
    qmlRegisterSingletonInstance<NetMusic>(
        "com.asmr.player",  // 模块名
        1, 0,               // 版本号
        "ASMRPlayer",       // QML 中访问的名称
        &asmr_player        // 实例指针
    );
    //qmlRegisterType<PageMgr>("PageMgr", 1, 0, "PageMgr");
    QQmlApplicationEngine engine;
    CursorPosProvider mousePosProvider;
    
    engine.rootContext()->setContextProperty("mousePosition", &mousePosProvider);
    QUrl url(QString("qrc:/QML/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1); // 加载失败时退出
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
