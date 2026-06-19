import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

Window {
    id: filePreview
    visible: false
    width: 960
    height: 600
    title: fileName
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: theme.leftBarColor

    property string filePath: ""
    property string fileName: ""
    property string fileType: ""  // "text" | "image"
    property bool loading: false
    property bool isMarkdown: false
    property bool isLocalFile: false
    property string currentEncoding: "UTF-8"

    property var targetWindow: null

    function close() {
        filePreview.visible = false
        filePreview.filePath = ""
        filePreview.fileName = ""
        filePreview.fileType = ""
        filePreview.loading = false
        filePreview.isMarkdown = false
        filePreview.isLocalFile = false
        filePreview.currentEncoding = "UTF-8"
    }

    function syncPosition() {
        if (targetWindow) {
            filePreview.x = targetWindow.x
            filePreview.y = targetWindow.y
            filePreview.width = targetWindow.width
            filePreview.height = targetWindow.height
        }
    }

    function openPreview(localPath) {
        filePath = localPath
        var name = localPath.split("/").pop().split("\\").pop()
        fileName = name
        var ext = name.split(".").pop().toLowerCase()
        var imageExts = ["png","jpg","jpeg","gif","bmp","svg","webp","ico"]

        syncPosition()
        filePreview.visible = true
        filePreview.raise()
        filePreview.requestActivate()
        isLocalFile = true

        if (imageExts.indexOf(ext) >= 0) {
            fileType = "image"
            loading = true
            imageItem.source = ""
            imageItem.source = localPath
            imageItem.rotation = 0
            imageItem.scale = 1.0
        } else {
            fileType = "text"
            isMarkdown = (ext === "md" || ext === "markdown")
            loading = true
            loadTextWithEncoding(localPath, currentEncoding)
        }
    }

    function openPreviewUrl(url, name, type) {
        filePath = url
        fileName = name
        fileType = type
        isLocalFile = false

        syncPosition()
        filePreview.visible = true
        filePreview.raise()
        filePreview.requestActivate()

        if (type === "image") {
            loading = true
            imageItem.source = ""
            imageItem.source = url
            imageItem.rotation = 0
            imageItem.scale = 1.0
        }
    }

    function openPreviewTextContent(name, content) {
        filePath = ""
        fileName = name
        fileType = "text"
        isLocalFile = false
        var ext = name.split(".").pop().toLowerCase()
        isMarkdown = (ext === "md" || ext === "markdown")

        syncPosition()
        filePreview.visible = true
        filePreview.raise()
        filePreview.requestActivate()

        textArea.textFormat = isMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
        textArea.text = content
        textFlickable.contentY = 0
        loading = false
    }

    function openPreviewTextLoading(name) {
        filePath = ""
        fileName = name
        fileType = "text"
        isLocalFile = false
        var ext = name.split(".").pop().toLowerCase()
        isMarkdown = (ext === "md" || ext === "markdown")
        loading = true
        textArea.text = ""

        syncPosition()
        filePreview.visible = true
        filePreview.raise()
        filePreview.requestActivate()
    }

    function updateTextContent(content) {
        textArea.textFormat = isMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
        textArea.text = content
        textFlickable.contentY = 0
        loading = false
    }

    // 用指定编码读取本地文件
    function loadTextWithEncoding(path, encoding) {
        loading = true
        var content = ASMRPlayer.readFileContent(path, encoding)
        textArea.textFormat = isMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
        textArea.text = content
        textFlickable.contentY = 0
        loading = false
    }

    // 切换编码后重新加载
    function reloadWithEncoding(encoding) {
        currentEncoding = encoding
        if (isLocalFile && fileType === "text" && filePath) {
            loadTextWithEncoding(filePath, encoding)
        }
    }

    // 顶部工具栏
    Rectangle {
        id: toolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        color: theme.contentColor
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: filePreview.fileName
                color: theme.fontColor
                font.pixelSize: 13
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            // 编码选择器（仅本地文本文件显示）
            ComboBox {
                visible: filePreview.isLocalFile && filePreview.fileType === "text" && !filePreview.loading
                model: ["UTF-8", "GB2312"]
                currentIndex: model.indexOf(filePreview.currentEncoding)
                implicitWidth: 90
                implicitHeight: 26
                font.pixelSize: 11
                onActivated: function(index) {
                    filePreview.reloadWithEncoding(model[index])
                }
                background: Rectangle {
                    color: theme.leftBarColor
                    radius: 4
                    border.color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.2)
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.displayText
                    color: theme.fontColor
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                delegate: ItemDelegate {
                    width: parent.width
                    height: 28
                    contentItem: Text {
                        text: modelData
                        color: theme.fontColor
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        color: hovered ? Qt.rgba(theme.globalColor.r, theme.globalColor.g, theme.globalColor.b, 0.2) : "transparent"
                    }
                }
                popup {
                    y: parent.height
                    width: parent.width
                    background: Rectangle {
                        color: theme.leftBarColor
                        radius: 4
                        border.color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.2)
                        border.width: 1
                    }
                }
            }

            // 图片旋转按钮
            Rectangle {
                visible: filePreview.fileType === "image" && !filePreview.loading
                width: 20; height: 20
                color: "transparent"
                Text {
                    id: rotateText; anchors.centerIn: parent
                    text: "↻"; font.pixelSize: 16; color: theme.fontColor
                    visible: false
                }
                MultiEffect {
                    source: rotateText; anchors.fill: rotateText
                    brightness: rotateMouse.containsMouse ? 1 : theme.globalBrightness
                    colorization: rotateMouse.containsMouse ? 1 : 0
                    colorizationColor: theme.globalColor
                }
                MouseArea {
                    id: rotateMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: imageItem.rotation += 90
                }
            }

            // 关闭按钮
            Rectangle {
                width: 20; height: 20
                color: "transparent"
                Text {
                    id: closeText; anchors.centerIn: parent
                    text: "✕"; font.pixelSize: 14; color: theme.fontColor
                    visible: false
                }
                MultiEffect {
                    source: closeText; anchors.fill: closeText
                    brightness: closeMouseArea.containsMouse ? 1 : theme.globalBrightness
                    colorization: closeMouseArea.containsMouse ? 1 : 0
                    colorizationColor: theme.globalColor
                }
                MouseArea {
                    id: closeMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: filePreview.close()
                }
            }
        }
    }

    // ===== 加载动画（居中） =====
    Item {
        id: loadingOverlay
        visible: filePreview.loading
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        z: 5

        Column {
            anchors.centerIn: parent
            spacing: 12

            Image {
                id: loadingIcon
                width: 50; height: 50
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/sources/image/loading.svg"
                visible: false
                mipmap: true
                smooth: true
            }
            MultiEffect {
                source: loadingIcon
                width: loadingIcon.width; height: loadingIcon.height
                anchors.horizontalCenter: parent.horizontalCenter
                brightness: theme.globalBrightness
                colorization: 0
                colorizationColor: theme.globalColor
                rotation: 0
                NumberAnimation on rotation {
                    from: 0; to: 360
                    duration: 1500
                    loops: Animation.Infinite
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "加载中..."
                color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.5)
                font.pixelSize: 12
            }
        }
    }

    // ===== 文本/MD 预览（居中内容） =====
    Flickable {
        id: textFlickable
        visible: filePreview.fileType === "text" && !filePreview.loading
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        clip: true
        contentWidth: width
        contentHeight: textArea.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        property bool needsScroll: contentHeight > height + 1
        ScrollBar.vertical: ScrollBar {
            id: textScrollBar
            anchors.right: parent.right
            policy: textFlickable.needsScroll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            width: textFlickable.needsScroll ? 6 : 0
            visible: textFlickable.needsScroll
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: theme.globalColor
                opacity: textScrollBar.active ? 0.6 : 0.2
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        TextArea {
            id: textArea
            width: textFlickable.width
            readOnly: true
            wrapMode: TextArea.Wrap
            color: theme.fontColor
            font.pixelSize: 14
            font.family: "Consolas, Courier New, monospace"
            textFormat: TextEdit.PlainText
            background: null
            selectByMouse: true
        }
    }

    // ===== 图片预览（居中） =====
    Flickable {
        id: imageFlickable
        visible: filePreview.fileType === "image" && !filePreview.loading
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        // 内容区域始终 >= 视口尺寸，避免 contentX/Y 被钳制导致图片偏移
        contentWidth: Math.max(width, imageItem.width * imageItem.scale)
        contentHeight: Math.max(height, imageItem.height * imageItem.scale)
        // 图片小于视口时自动居中
        contentX: imageItem.width * imageItem.scale < width ? (width - imageItem.width * imageItem.scale) / 2 : 0
        contentY: imageItem.height * imageItem.scale < height ? (height - imageItem.height * imageItem.scale) / 2 : 0
        boundsBehavior: Flickable.StopAtBounds
        property bool needsVScroll: imageItem.height * imageItem.scale > height + 1
        property bool needsHScroll: imageItem.width * imageItem.scale > width + 1
        ScrollBar.vertical: ScrollBar {
            id: imgScrollBarV
            anchors.right: parent.right
            policy: imageFlickable.needsVScroll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            width: imageFlickable.needsVScroll ? 6 : 0
            visible: imageFlickable.needsVScroll
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: 6; implicitHeight: 6; radius: 3
                color: theme.globalColor
                opacity: imgScrollBarV.active ? 0.6 : 0.2
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
        ScrollBar.horizontal: ScrollBar {
            id: imgScrollBarH
            anchors.bottom: parent.bottom
            policy: imageFlickable.needsHScroll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            height: imageFlickable.needsHScroll ? 6 : 0
            visible: imageFlickable.needsHScroll
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: 6; implicitHeight: 6; radius: 3
                color: theme.globalColor
                opacity: imgScrollBarH.active ? 0.6 : 0.2
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Image {
            id: imageItem
            fillMode: Image.PreserveAspectFit
            width: imageFlickable.width
            height: imageFlickable.height
            sourceSize.width: 0
            mipmap: true
            smooth: true
            cache: false
            transformOrigin: Item.Center
            onStatusChanged: {
                if (status === Image.Ready || status === Image.Error) {
                    filePreview.loading = false
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: function(wheel) {
                var delta = wheel.angleDelta.y > 0 ? 0.1 : -0.1
                var newScale = Math.max(0.1, Math.min(10, imageItem.scale + delta))
                imageItem.scale = newScale
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: filePreview.close()
    }
}
