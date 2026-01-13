#pragma once

#include <QObject>
#include <QPointF>  // 添加这个头文件以使用 QPointF
#include <QCursor>  // 添加这个头文件以使用 QCursor
#include <qscreen.h>
class CursorPosProvider : public QObject
{
    Q_OBJECT
public:
    explicit CursorPosProvider(QObject* parent = nullptr) : QObject(parent)
    {
    }
    virtual ~CursorPosProvider() = default;

    Q_INVOKABLE QPointF cursorPos()
    {
        return QCursor::pos();
    }
    Q_INVOKABLE int screenWidth()
    {
        // 获取应用程序的主屏幕（若有多个屏幕，可调整为获取鼠标所在屏幕）
        QScreen* primaryScreen = QGuiApplication::primaryScreen();
        if (primaryScreen)
        {
            // 获取屏幕可用区域宽度（排除任务栏等系统控件）
            return primaryScreen->availableGeometry().width();
            // 若要获取屏幕物理总宽度，改用：
            // return primaryScreen->geometry().width();
        }
        return 0; // 异常情况返回0
    }
        
    Q_INVOKABLE int screenHeight()
    {
        QScreen* primaryScreen = QGuiApplication::primaryScreen();
        if (primaryScreen)
        {
            // 获取屏幕可用区域高度
            return primaryScreen->availableGeometry().height();
            // 若要获取屏幕物理总高度，改用：
            // return primaryScreen->geometry().height();
        }
        return 0;
    }
};