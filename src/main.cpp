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
    engine.load(url);

    return app.exec();
}
