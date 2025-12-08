#pragma once

#include <QObject>
#include <QString>
#include <QTcpServer>
#include <QTcpSocket>
#include <QHostAddress>
class NumberToChinese  : public QObject
{
	Q_OBJECT

public:
	explicit NumberToChinese(QObject* parent = nullptr) : QObject(parent)
	{}
	virtual ~NumberToChinese() = default;
		
	Q_INVOKABLE QString GetNumber(double a);

};

