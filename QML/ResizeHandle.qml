// ResizeHandle.qml
import QtQuick
import QtQuick.Window

Item {
    id: root
    anchors.fill: parent

    //开关：默认全部禁用
    property bool rightEnabled: false      // 右侧边
    property bool bottomEnabled: false     // 底边
    property bool cornerEnabled: false     // 右下角

    readonly property var win: Window.window

    //右下角
    MouseArea {
        id: cornerHandle
        visible: root.cornerEnabled      // 开关控制
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        width: 8; height: 8
        cursorShape: Qt.SizeFDiagCursor
        onPressed: root.win.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
    }

    //右边
    MouseArea {
        id: rightHandle
        visible: root.rightEnabled
        anchors {
            top: parent.top; bottom: parent.bottom
            right: parent.right
            bottomMargin: cornerHandle.visible ? 8 : 0   // 避开角落
            topMargin:    cornerHandle.visible ? 8 : 0
        }
        width: 8
        cursorShape: Qt.SizeHorCursor
        onPressed: root.win.startSystemResize(Qt.RightEdge)
    }

    //底边
    MouseArea {
        id: bottomHandle
        visible: root.bottomEnabled
        anchors {
            left: parent.left; right: parent.right
            bottom: parent.bottom
            rightMargin: cornerHandle.visible ? 8 : 0
            leftMargin:  cornerHandle.visible ? 8 : 0
        }
        height: 8
        cursorShape: Qt.SizeVerCursor
        onPressed: root.win.startSystemResize(Qt.BottomEdge)
    }
}