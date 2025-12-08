#pragma once

#include <QObject>
#include <QString>
#include <QTcpSocket>
#include <QHostAddress>
#include <QDebug>

// 建议将类名修改为更能体现其功能的名称，比如 TcpClient
class TcpClient : public QObject
{
    Q_OBJECT

    // 用于在 QML 中访问当前的连接状态
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)

public:
    explicit TcpClient(QObject *parent = nullptr) : QObject(parent),
        tcpSocket(new QTcpSocket(this)),
        m_connected(false)
    {
        // 连接 QTcpSocket 的关键信号到我们的槽函数
        connect(tcpSocket, &QTcpSocket::connected, this, &TcpClient::onConnected);
        connect(tcpSocket, &QTcpSocket::disconnected, this, &TcpClient::onDisconnected);
        connect(tcpSocket, &QTcpSocket::readyRead, this, &TcpClient::onReadyRead);
        connect(tcpSocket, &QTcpSocket::errorOccurred, this, &TcpClient::onErrorOccurred);
    }

    virtual ~TcpClient() = default;

    // Q_INVOKABLE 用于从 QML 调用
    Q_INVOKABLE void connectToServer(const QString &hostName = "47.96.159.221", quint16 port = 7561);
    Q_INVOKABLE void disconnectFromServer();
    Q_INVOKABLE void sendMessage(const QString &message);

    // Q_PROPERTY 的 READ 函数
    bool isConnected() const;

signals:
    // 通知 QML 连接状态已更改
    void connectedChanged(bool connected);
    // 通知 QML 收到了新消息
    void messageReceived(const QString &message);
    // 通知 QML 发生了错误
    void errorOccurred(const QString &errorString);

private slots:
    // 内部槽函数，用于处理 socket 事件
    void onConnected();
    void onDisconnected();
    void onReadyRead();
    void onErrorOccurred(QAbstractSocket::SocketError socketError);

private:
    QTcpSocket *tcpSocket;
    bool m_connected; // 用于存储连接状态
};
