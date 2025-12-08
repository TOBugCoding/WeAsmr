// fpscounter.h
#pragma once
#include <QObject>
#include <QElapsedTimer>

/* 注册到 QML 的 FPS 计算器，每秒把帧率打印到控制台 */
class FpsCounter : public QObject
{
    Q_OBJECT
        Q_PROPERTY(int fps READ fps NOTIFY fpsChanged)   // 如果 QML 里也想绑定
public:
    explicit FpsCounter(QObject* parent = nullptr);
    int fps() const { return m_fps; }

public slots:
    /* 每帧调用一次 */
    void update();

signals:
    void fpsChanged();

private:
    int     m_frameCount = 0;
    int     m_fps = 0;
    qreal   m_timeSum = 0;          // 累计时间（秒）
    QElapsedTimer m_timer;
};
