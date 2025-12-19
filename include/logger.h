#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QDebug>

class logger : public QObject
{
    Q_OBJECT
public:
    explicit logger(QObject *parent = nullptr);
    Q_INVOKABLE void process();
signals:
    void siganl(int rely);
private slots:
    void slot(int rely);
};

#endif // LOGGER_H
