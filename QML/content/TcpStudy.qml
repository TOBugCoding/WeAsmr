import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import TcpClient
Item {
    anchors.fill:parent
    TcpClient {
        id: tcpClient
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: tcpClient.connected ? "已连接" : "未连接"
            color: tcpClient.connected ? "green" : "red"
            font.pointSize: 14
        }

        Button {
            text: "连接服务器"
            onClicked: {
                tcpClient.connectToServer("47.96.159.221", 7561)
            }
        }

        Button {
            text: "断开连接"
            onClicked: {
                tcpClient.disconnectFromServer()
            }
        }

        TextField {
            id: inputField
            placeholderText: "输入要发送的数字..."
            Layout.preferredWidth: 200
        }

        Button {
            text: "发送"
            onClicked: {
                if (inputField.text) {
                    // 2. 调用 C++ 中的 sendMessage 方法
                    tcpClient.sendMessage(inputField.text)
                    inputField.text = ""
                }
            }
        }

        Text {
            text: "服务器回复: " + receivedMessage
            Layout.preferredWidth: 400
            wrapMode: Text.WordWrap
        }
    }

    // 3. 响应 C++ 发出的信号
    Connections {
        target: tcpClient

        // 当收到消息时更新 QML 界面
        function onMessageReceived(message) {
            console.log("QML 收到消息:", message)
            receivedMessage = message
        }

        // 当发生错误时显示
        function onErrorOccurred(errorString) {
            console.log("错误:", errorString)
            // 你可以在这里用一个对话框来显示错误
        }
    }

    property string receivedMessage: ""
}
