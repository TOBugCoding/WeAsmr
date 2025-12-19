import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtMultimedia

Item {
    id: study
    opacity: 0
    Button{
        text:"点击测试"
        onClicked: {console.log("检测到点击")}
    }
    Button{
        z:2001
        anchors.top:parent.top
        anchors.topMargin: 100
        text:"显示/关闭";
        onClicked: {overlay.visible=!overlay.visible;console.log("切换到"+overlay.visible)}
    }
    Rectangle {
        z:2000
        id: overlay
        anchors.fill: parent
        color: "red"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons  // 接受所有鼠标按钮事件
            propagateComposedEvents: false  // 阻止事件穿透
            hoverEnabled: true  // 启用悬停事件处理
            // 阻止所有鼠标事件穿透
            onPressed: function(mouse) { mouse.accepted = true }
            onReleased: function(mouse) { mouse.accepted = true }
            onDoubleClicked: function(mouse) { mouse.accepted = true }
            onWheel: function(wheel) { wheel.accepted = true }
        }
    }



}
