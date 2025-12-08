#include "DataMgr.h"

DataMgr::DataMgr(QObject *parent)
	: QObject(parent)
{}

DataMgr::~DataMgr()
{
	qDebug() << "DataMgr::~DataMgr()";
}

QVector<QString> DataMgr::GetData()
{
	QVector<QString> data{"ceshi1","ceshi2"};
	return data;
}
