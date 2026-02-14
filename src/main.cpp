#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQmlContext>

#include <QLocalServer>
#include <QLocalSocket>
#include "CursorPosProvider.h"
#include "netMusic.h"
#include "DownloadToolMgr.h"

int main(int argc, char* argv[])
{
    QString serverName = "AsmrMoonServer";
    QLocalSocket socket;
    socket.connectToServer(serverName);
    if (socket.waitForConnected(1000)) {
        return -1;
    }

    QLocalServer server;
    if (server.listen(serverName)) {
        // 此时监听失败，可能是程序崩溃时,残留进程服务导致的,移除之
        if(server.serverError()== QAbstractSocket::AddressInUseError){
            QLocalServer::removeServer(serverName);
            server.listen(serverName);
        }
    }

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/fonts/icon.ico"));
    QString version = "3.2.2";
    app.setApplicationVersion(version);
    QDir dir;

    // 检查文件夹是否存在，如果不存在则创建
    if (!dir.exists("download")) {
        if (dir.mkpath("download")) {
            qDebug() << "文件夹创建成功：";
        } else {
            qDebug() << "文件夹创建失败！";
        }
    } else {
        qDebug() << "文件夹已存在：";
    }
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
    engine.rootContext()->setContextProperty("appDir", qApp->applicationDirPath());
    QUrl url(QString("qrc:/QML/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1); // 加载失败时退出
                     }, Qt::QueuedConnection);

    QObject::connect(&server, &QLocalServer::newConnection, &server, [&engine]() {
        QObject *qmlRootObj = nullptr;
        const QList<QObject*> rootObjects = engine.rootObjects(); // 具名局部变量
        if (!rootObjects.isEmpty()) {                             // 对具名变量操作
            qmlRootObj = rootObjects.first();
        }
        QMetaObject::invokeMethod(
        qmlRootObj,
        "raiseAndShowWindow",
        Qt::QueuedConnection
        );

    });
    engine.load(url);

    return app.exec();
}
