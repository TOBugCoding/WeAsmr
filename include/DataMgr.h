#pragma once

#include <QObject>
#include <qstring.h>
#include <qvector.h>
#include <qdebug.h>
#include <vector>
class DataMgr  : public QObject
{
	Q_OBJECT

public:
	DataMgr(QObject *parent=nullptr);
	~DataMgr();
	Q_INVOKABLE QVector<QString> GetData();
private:
	QVector<QString> data;
	std::vector<std::string> numbers;
};

