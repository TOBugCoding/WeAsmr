// Aboutme.qml
import QtQuick
import QtQuick.Layouts
import "../components"
Item {
    id: root
    visible: true
    opacity:0 //初始透明度为0 动画加载过渡
    // 数据模型
    property var aboutItems: [
        { icon: "💼", label: "主要功能", value: "ASMR音频在线播放" },
        { icon: "🔐", label: "技术兴趣", value: "Qt客户端、游戏客户端、Linux" },
        { icon: "🎨", label: "爱好创作", value: "交互界面开发、美学编程" },
        { icon: "🤯", label: "奇妙想法", value: "追求技术服务于生活" }
    ]
    //property var aboutItems: [
    //   { icon: "💼", label: "专业方向", value: "计算机科学与技术" },
    //    { icon: "🔐", label: "技术兴趣", value: "Qt客户端、游戏客户端、Linux" },
    //    { icon: "🎨", label: "爱好创作", value: "交互界面开发、美学编程" },
    //    { icon: "🤯", label: "奇妙想法", value: "追求技术服务于生活" }
    //]
    property int currentIndex: 0
    property string currentText: ""      // 当前正在显示的文本
    property bool isTyping: true         // true=打字中，false=删除中
    property int charIndex: 0            // 当前字符索引

    // 打字机定时器
    Timer {
        id: typewriterTimer
        interval: 80   // 每80ms打一个字
        repeat: true
        running: false

        onTriggered: {
            let item = root.aboutItems[root.currentIndex]
            let fullText = item.icon + " " + item.label + ": " + item.value

            if (root.isTyping) {
                // 正在打字
                root.charIndex += 1
                if (root.charIndex >= fullText.length) {
                    // 打完，停止打字机，启动延迟
                    root.isTyping = false
                    root.charIndex = fullText.length
                    root.currentText = fullText
                    typewriterTimer.stop()   // 👈 关键：停止定时器，避免干扰延迟
                    delayTimer.start()
                    return
                }
                root.currentText = fullText.substring(0, root.charIndex)
            } else {
                // 正在删除
                root.charIndex -= 1
                if (root.charIndex <= 0) {
                    // 删除完毕，切换到下一项
                    root.currentIndex = (root.currentIndex + 1) % root.aboutItems.length
                    root.isTyping = true
                    root.charIndex = 0
                    root.currentText = ""
                    typewriterTimer.interval = 80 // 重置打字速度
                    typewriterTimer.start()       // 重新开始打字
                    return
                }
                root.currentText = fullText.substring(0, root.charIndex)
            }
        }
    }

    // 延迟
    Timer {
        id: delayTimer
        interval: 1500
        repeat: false
        onTriggered: {
            typewriterTimer.interval = 30  // 删除更快一点
            typewriterTimer.start()        // 开始删除
        }
    }

    Column {
        //anchors.centerIn: parent,这里加上，字体就会随着窗口跑了
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.left:parent.left
        anchors.leftMargin: 50
        spacing: 16

        Text {
            text: "Hello!我是"
            font.pixelSize: 36
            color: theme.textColor
            font.weight: Font.Bold
        }

        Text {
            text: "大师哥we"
            font.pixelSize: 48
            color: theme.focusColor
            font.weight: Font.Bold
        }
        Text {
            text: "邮箱:2153549054@qq.com"
            font.pixelSize: 48
            color: theme.textColor
            font.weight: Font.Bold
        }
        Text {
            text: "欢迎客户端学习交流分享"
            font.pixelSize: 36
            color: theme.focusColor
            font.weight: Font.Normal
        }

        Item {
            width: parent.width
            height: 36
            Row {
                spacing: 12
                anchors.verticalCenter: parent.verticalCenter

                // 当前图标
                Text {
                    text: root.aboutItems[root.currentIndex].icon
                    font.pixelSize: 20
                    color: "#00bfff"
                }

                // 标签 + 值
                Text {
                    id: typewriterDisplay
                    text: root.currentText
                    font.pixelSize: 18
                    color: theme.focusColor
                    font.weight: Font.Bold
                }

                // 光标闪烁
                Text {
                    id: cursor
                    text: "|"
                    font.pixelSize: 18
                    color: theme.focusColor
                    font.weight: Font.Bold
                    visible: root.currentText.length > 0

                    Timer {
                        id: blinkTimer
                        interval: 500
                        repeat: true
                        running: root.currentText.length > 0

                        onTriggered: {
                            cursor.visible = !cursor.visible
                        }
                    }
                }
            }
        }

        // 启动打字机
        Component.onCompleted: {
            typewriterTimer.start()
        }

        // 按钮行
        RowLayout {
            spacing: 20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 20

            EButton {
                iconCharacter: "\uf006"
                iconFontFamily: iconFont.name
                iconRotateOnClick: true
                iconColor: "#E3B341"
                text: "关于我"
                onClicked: {
                        Qt.openUrlExternally("https://github.com/TOBugCoding/WeAsmr")  // 替换为你想跳转的网址
                    }
            }
        }
    }
}
