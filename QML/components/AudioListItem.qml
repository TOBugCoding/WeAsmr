// AudioListItem.qml — 通用音频列表项组件
// 提供：hover 缩放动画、下载进度条、背景高亮、取消下载按钮
// 页面通过 default property 注入按钮到 buttonRow，点击事件通过回调处理
import QtQuick
import QtQuick.Layouts
import com.asmr.player 1.0
import ".."

Item {
    id: root
    width: ListView.view ? ListView.view.width - 30 : 400
    height: 50

    // ===== 外部接口 =====
    property string itemName: ""               // 显示名称
    property string downloadUrl: ""            // 下载进度查询 key
    property string cancelUrl: ""              // 取消下载 URL（默认 = downloadUrl）
    property string currentPlaying: ""         // 当前播放路径
    property string playingComparePath: ""     // 高亮比较路径（默认 = downloadUrl）
    property real   downloadProgress: downloadUrl ? dowloadmgr.getDownloadProgress(downloadUrl) : 0
    property alias  scaleContainer: scaleContainer
    property alias  bgRect: bgRect
    default property alias content: buttonRow.data   // 页面注入的按钮（进入左侧 Row）

    // 点击回调（页面赋值函数）
    property var handleClick: null    // function(mouse) — 左键/右键统一处理
    property int  mouseAcceptedButtons: Qt.LeftButton

    // ===== 内部 =====
    property string _cancelUrl: cancelUrl || downloadUrl
    property string _comparePath: playingComparePath || downloadUrl

    PropertyAnimation {
        id: scaleGrowAnim
        target: scaleContainer
        property: "scale"
        from: 1.0; to: 1.02
        duration: 200
        easing.type: Easing.OutQuad
    }
    PropertyAnimation {
        id: scaleRestoreAnim
        target: scaleContainer
        property: "scale"
        to: 1.0
        duration: 200
        easing.type: Easing.OutQuad
    }

    Item {
        id: scaleContainer
        anchors.fill: parent
        transformOrigin: Item.Center

        // 背景
        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: "#00000000"
            opacity: 0.2
            radius: 4
        }

        // 下载进度条
        Rectangle {
            id: progressBar
            color: theme.dowloadColor
            opacity: 0.8
            radius: 4
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.downloadProgress * parent.width
            visible: root.downloadProgress > 0 && root.downloadProgress < 1
            Behavior on width {
                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
            }
        }

        // 操作按钮行（页面通过 default property 注入）
        Row {
            id: buttonRow
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 15
        }

        // 名称文本（按钮右侧，填充剩余空间）
        Text {
            id: nameText
            anchors.left: buttonRow.right
            anchors.leftMargin: 15
            anchors.right: cancelBtn.visible ? cancelBtn.left : parent.right
            anchors.rightMargin: cancelBtn.visible ? 10 : 15
            anchors.verticalCenter: parent.verticalCenter
            text: root.itemName
            font.pixelSize: 16
            color: currentPlaying === _comparePath ? theme.green : theme.fontColor
            elide: Text.ElideRight
        }

        // 取消下载按钮
        HoverButton {
            id: cancelBtn
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            z: 2
            visible: root.downloadProgress > 0 && root.downloadProgress < 1
            image_path: "qrc:/sources/image/取消下载.svg"
            onClicked: dowloadmgr.candelDownload(_cancelUrl)
        }

        // 鼠标区域（组件自管理，页面通过 handleClick 回调处理点击）
        MouseArea {
            id: bgMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: -1
            acceptedButtons: root.mouseAcceptedButtons
            onClicked: function(mouse) {
                if (root.handleClick) root.handleClick(mouse)
            }
            onEntered: {
                if (scaleRestoreAnim.running) scaleRestoreAnim.stop()
                if (!scaleGrowAnim.running) scaleGrowAnim.start()
                bgRect.color = theme.fontColor
            }
            onExited: {
                if (scaleGrowAnim.running) scaleGrowAnim.stop()
                if (!scaleRestoreAnim.running) scaleRestoreAnim.start()
                bgRect.color = "#00000000"
            }
        }
    }

    Connections {
        target: dowloadmgr
        function onDownloadProgressUpdated(url, progress) {
            if (url === root.downloadUrl) {
                root.downloadProgress = progress
            }
        }
    }
}
