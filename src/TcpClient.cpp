#include "TcpClient.h"

// 连接到服务器
void TcpClient::connectToServer(const QString &hostName, quint16 port)
{
    if (tcpSocket->state() == QTcpSocket::ConnectedState) {
        qDebug() << "已经连接到服务器，无需重复连接。";
        return;
    }
    qDebug() << "正在连接到 " << hostName << ":" << port;
    tcpSocket->connectToHost(hostName, port);
}

// 断开与服务器的连接
void TcpClient::disconnectFromServer()
{
    if (tcpSocket->state() != QTcpSocket::UnconnectedState) {
        tcpSocket->disconnectFromHost();
    }
}

// 发送消息
void TcpClient::sendMessage(const QString &message)
{
    if (tcpSocket->state() == QTcpSocket::ConnectedState) {
        // 通常在发送字符串时，最好加上一个换行符作为结束标志，方便服务器解析
        QByteArray data = message.toUtf8() + "\r\n";
        tcpSocket->write(data);
        qDebug() << "发送消息:" << message;
    } else {
        QString errorMsg = "发送失败：未连接到服务器。";
        qDebug() << errorMsg;
        emit errorOccurred(errorMsg); // 发送错误信号
    }
}

// 获取当前连接状态
bool TcpClient::isConnected() const
{
    return m_connected;
}



// 槽函数
// 槽函数：连接成功时调用
void TcpClient::onConnected()
{
    qDebug() << "成功连接到服务器！";
    m_connected = true;
    emit connectedChanged(m_connected); // 立即更新m_connected ,qml立即同步
}

// 槽函数：连接断开时调用
void TcpClient::onDisconnected()
{
    qDebug() << "与服务器断开连接。";
    m_connected = false;
    emit connectedChanged(m_connected); // 通知 QML 连接状态已变为 false
}

// 槽函数：有数据可读时调用
void TcpClient::onReadyRead()
{
    // 读取所有可用数据
    QByteArray data = tcpSocket->readAll();
    QString receivedMessage = QString::fromUtf8(data).trimmed(); // trimmed() 去除首尾的空白字符和换行符

    qDebug() << "收到服务器消息:" << receivedMessage;

    // 发送信号到 QML
    emit messageReceived(receivedMessage);
}

// 槽函数：发生错误时调用
void TcpClient::onErrorOccurred(QAbstractSocket::SocketError socketError)
{
    Q_UNUSED(socketError); // 忽略 socketError 参数，我们直接使用 errorString()
    QString errorMsg = tcpSocket->errorString();
    qDebug() << "网络错误:" << errorMsg;
    emit errorOccurred(errorMsg); // 通知 QML 发生了错误
}
