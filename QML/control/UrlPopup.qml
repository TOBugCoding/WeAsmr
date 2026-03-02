import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QuickVLC
import QtQuick.Controls.Basic
import "../"
Popup {
    id: popupController
    width: Math.min(500, root.width - 40)
    // 优化弹窗基础样式
    focus: true               // 弹窗获取焦点
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent // 按ESC或点击外部关闭
    padding: 16               // 弹窗内边距，提升空间感
    background: Rectangle {   // 自定义弹窗背景
        color: theme.leftBarColor      // 白色背景
        radius: 12            // 圆角，更现代
        border.width: 1       // 轻微边框
        border.color: "#e0e0e0"
        // 阴影效果
        layer.enabled: true

    }

    required property MediaPlayer mediaPlayer

    function loadUrl(url) {
        popupController.mediaPlayer.setSafeUrl(url)
    }

    ColumnLayout {  // 改用ColumnLayout，增加标题栏
        id: mainLayout
        anchors.fill: parent
        spacing: 12  // 控件间距

        // 标题栏
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop

            Label {
                text: qsTr("加载网络视频流")
                font.pixelSize: 16
                font.bold: true
                color: theme.fontColor
                Layout.alignment: Qt.AlignLeft
            }

            Item { Layout.fillWidth: true } // 占位符，推挤关闭按钮到右侧

            // 关闭按钮
            HoverButton {
                image_path:"qrc:/sources/image/close.svg"
                onClicked: popupController.close()
            }
        }

        // 核心输入区域
        RowLayout {
            id: rowOpenUrl
            Layout.fillWidth: true
            spacing: 8  // 控件间紧凑一点

            Label {
                text: qsTr("URL:");
                font.pixelSize: 14
                color: theme.fontColor
                Layout.alignment: Qt.AlignVCenter  // 垂直居中
            }

            TextField {
                id: urlText
                Layout.fillWidth: true
                focus: true
                // 输入框样式优化
                placeholderText: qsTr("输入视频流地址 (如 rtsp://xxx 或 http://xxx)")
                wrapMode: TextInput.WrapAnywhere
                font.pixelSize: 14
                // 自定义输入框样式
                background: Rectangle {
                    color: "#fafafa"
                    border.width: 1
                    border.color: urlText.focused ? "#2196F3" : "#e0e0e0"
                    radius: 6
                }
                // 内边距
                padding: 8
                // 选中时高亮
                selectionColor: "#ffffff"
                selectedTextColor: "#2196F3"

                Keys.onReturnPressed: {
                    popupController.loadUrl(text)
                    urlText.text = ""
                    popupController.close()
                }
            }

            Button {
                text: qsTr("加载")
                enabled: urlText.text.trim() !== ""  // 排除纯空格
                // 按钮样式优化
                font.pixelSize: 14
                padding: 8  // 按钮内边距
                // 自定义按钮样式
                background: Rectangle {
                    color: enabled ? theme.green : "#e0e0e0"
                    radius: 6
                }
                contentItem: Text {
                    text: parent.text
                    color: enabled ? "#ffffff" : "#9e9e9e"
                    font.pixelSize: 14
                }
                onClicked: {
                    popupController.loadUrl(urlText.text.trim())  // 去除首尾空格
                    urlText.text = ""
                    popupController.close()
                }
            }
        }

        // 提示文本（可选）
        Label {
            text: qsTr("支持 RTSP/HTTP/HLS 等主流视频流协议")
            font.pixelSize: 12
            color: "#9e9e9e"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            wrapMode: Text.WrapAnywhere
        }
    }

    // 弹窗打开时聚焦输入框
    onOpened: {
        urlText.forceActiveFocus()
    }
}
