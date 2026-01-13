#include "fpscounter.h"
#include <QDebug>

FpsCounter::FpsCounter(QObject* parent)
    : QObject(parent)
{
    m_timer.start();
}

void FpsCounter::update()
{
    ++m_frameCount;
    qreal elapsed = m_timer.elapsed() / 1000.0;   // 秒
    if (elapsed >= 1.0) {                        // 每满 1 s 计算一次
        m_fps = qRound(m_frameCount / elapsed);
        qDebug() << "[FPS]" << m_fps;            // 控制台打印
        m_frameCount = 0;
        m_timer.restart();
        emit fpsChanged();
    }
}