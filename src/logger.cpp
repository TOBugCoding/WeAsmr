#include "logger.h"

logger::logger(QObject *parent)
    : QObject{parent}
{
    qDebug()<<"测试\n";
    connect(this,&logger::siganl,this,&logger::slot);
    process();
}

void logger::slot(int rely){

    qDebug()<<"信号接收  "<<rely<<"\n";
}

void logger::process(){
    //模拟处理，处理完成后发射信号
    emit siganl(2);
}
