import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import QtWebEngine

Window {
    id: webPreview
    visible: false
    width: 1024
    height: 680
    title: fileName
    flags: Qt.Window | Qt.FramelessWindowHint
    color: theme.leftBarColor

    property string previewUrl: ""
    property string fileName: ""
    property string downloadUrl: ""

    property var targetWindow: null
    // 0=空闲 1=加载中 2=加载成功 3=加载失败
    property int loadState: 0

    function close() {
        webPreview.visible = false
        webPreview.previewUrl = ""
        webPreview.fileName = ""
        webPreview.downloadUrl = ""
        webPreview.loadState = 0
        webView.url = "about:blank"
    }

    function syncPosition() {
        if (targetWindow) {
            webPreview.x = targetWindow.x
            webPreview.y = targetWindow.y
            webPreview.width = targetWindow.width
            webPreview.height = targetWindow.height
        }
    }

    // Base64 编码函数
    function base64Encode(str) {
        var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
        var output = '';
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;
        str = unescape(encodeURIComponent(str));
        while (i < str.length) {
            chr1 = str.charCodeAt(i++);
            chr2 = str.charCodeAt(i++);
            chr3 = str.charCodeAt(i++);
            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;
            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }
            output = output + chars.charAt(enc1) + chars.charAt(enc2) + chars.charAt(enc3) + chars.charAt(enc4);
        }
        return output;
    }

    function openPreview(url, name) {
        downloadUrl = url
        fileName = name

        // kkfileview 预览链接生成：Base64 编码后再 URL 编码
        var kkfileServer = configMgr.getKkfileServer() || "http://47.96.159.221:8012"
        var base64Url = base64Encode(url)
        previewUrl = kkfileServer + "/onlinePreview?url=" + encodeURIComponent(base64Url)

        console.log("原始链接:", url)
        console.log("Base64编码:", base64Url)
        console.log("最终预览链接:", previewUrl)

        syncPosition()
        webPreview.loadState = 1  // 加载中
        webPreview.visible = true
        webPreview.raise()
        webPreview.requestActivate()

        // 加载预览页面
        webView.url = previewUrl
    }

    // 顶部工具栏
    Rectangle {
        id: toolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: theme.contentColor
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // 文件名（URL 解码显示）
            Text {
                text: decodeURIComponent(webPreview.fileName)
                color: theme.fontColor
                font.pixelSize: 13
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            // 刷新按钮
            Rectangle {
                width: 28; height: 28; radius: 4
                color: "transparent"
                Text {
                    id: refreshText; anchors.centerIn: parent
                    text: "↻"; font.pixelSize: 18; color: theme.fontColor
                    visible: false
                }
                MultiEffect {
                    source: refreshText; anchors.fill: refreshText
                    brightness: refreshMouse.containsMouse ? 1 : theme.globalBrightness
                    colorization: refreshMouse.containsMouse ? 1 : 0
                    colorizationColor: theme.globalColor
                }
                MouseArea {
                    id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: webView.reload()
                }
            }

            // 在浏览器中打开
            Rectangle {
                width: 28; height: 28; radius: 4
                color: "transparent"
                Text {
                    id: browserText; anchors.centerIn: parent
                    text: "🌑"; font.pixelSize: 16
                    color: "gray"
                    visible: false
                }
                MultiEffect {
                    source: browserText; anchors.fill: browserText
                    brightness: browserMouse.containsMouse ? 1 : theme.globalBrightness
                    colorization: browserMouse.containsMouse ? 1 : 0
                    colorizationColor: theme.globalColor
                }
                MouseArea {
                    id: browserMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(webPreview.previewUrl)
                }
            }

            // 关闭按钮
            Rectangle {
                width: 28; height: 28; radius: 4
                color: "transparent"
                Text {
                    id: closeText; anchors.centerIn: parent
                    text: "✕"; font.pixelSize: 16; color: theme.fontColor
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
                    onClicked: webPreview.close()
                }
            }
        }
    }

    // 加载动画（WebEngine 内容区居中）
    Item {
        id: loadingOverlay
        visible: webPreview.loadState === 1
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        z: 5

        // 半透明遮罩
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.leftBarColor.r, theme.leftBarColor.g, theme.leftBarColor.b, 0.85)
        }

        Column {
            anchors.centerIn: parent
            spacing: 14

            // 现代脉冲圆环动画
            Item {
                id: pulseRing
                width: 56; height: 56
                anchors.horizontalCenter: parent.horizontalCenter

                // 外圈脉冲
                Rectangle {
                    id: outerRing
                    anchors.centerIn: parent
                    width: 56; height: 56; radius: 28
                    color: "transparent"
                    border.width: 2.5
                    border.color: theme.globalColor
                    opacity: 0.3

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: loadingOverlay.visible
                        NumberAnimation { from: 0.6; to: 1.0; duration: 900; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 1.0; to: 0.6; duration: 0 }
                    }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: loadingOverlay.visible
                        NumberAnimation { from: 0.5; to: 0.0; duration: 900; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 0.0; to: 0.5; duration: 0 }
                    }
                }

                // 内圈脉冲（延迟）
                Rectangle {
                    id: innerRing
                    anchors.centerIn: parent
                    width: 40; height: 40; radius: 20
                    color: "transparent"
                    border.width: 2
                    border.color: theme.globalColor
                    opacity: 0.3

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: loadingOverlay.visible
                        PauseAnimation { duration: 300 }
                        NumberAnimation { from: 0.6; to: 1.0; duration: 900; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 1.0; to: 0.6; duration: 0 }
                    }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: loadingOverlay.visible
                        PauseAnimation { duration: 300 }
                        NumberAnimation { from: 0.5; to: 0.0; duration: 900; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 0.0; to: 0.5; duration: 0 }
                    }
                }

                // 中心旋转弧线
                Canvas {
                    id: arcCanvas
                    width: 28; height: 28
                    anchors.centerIn: parent
                    property real rotationAngle: 0

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.beginPath()
                        ctx.arc(width/2, height/2, 10, 0, Math.PI * 1.5)
                        ctx.strokeStyle = theme.globalColor
                        ctx.lineWidth = 2.5
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }

                    NumberAnimation on rotationAngle {
                        from: 0; to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: loadingOverlay.visible
                        easing.type: Easing.Linear
                    }
                    transform: Rotation {
                        origin.x: arcCanvas.width / 2
                        origin.y: arcCanvas.height / 2
                        angle: arcCanvas.rotationAngle
                    }

                    Connections {
                        target: loadingOverlay
                        function onVisibleChanged() {
                            if (loadingOverlay.visible) arcCanvas.requestPaint()
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "正在加载预览..."
                color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.5)
                font.pixelSize: 12
            }
        }
    }

    // 加载失败提示
    Item {
        id: errorOverlay
        visible: webPreview.loadState === 3
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        z: 5

        Column {
            anchors.centerIn: parent
            spacing: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "⚠"
                font.pixelSize: 40
                color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.4)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "预览加载失败"
                color: theme.fontColor
                font.pixelSize: 16
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "可能是文件格式不支持或服务器无法访问"
                color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.5)
                font.pixelSize: 12
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: retryText.implicitWidth + 24
                height: 32
                radius: 4
                color: retryMouse.containsMouse ? theme.globalColor : theme.contentColor
                Text {
                    id: retryText
                    anchors.centerIn: parent
                    text: "重试"
                    color: theme.fontColor
                    font.pixelSize: 13
                }
                MouseArea {
                    id: retryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        webPreview.loadState = 1
                        webView.reload()
                    }
                }
            }
        }
    }

    // WebEngineView 内容区域（加载时隐藏，避免自带加载条与自定义动画重叠）
    WebEngineView {
        id: webView
        visible: webPreview.loadState === 2
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        url: "about:blank"

        // 设置 WebEngine 属性
        settings.javascriptEnabled: true
        settings.pluginsEnabled: true
        settings.pdfViewerEnabled: true

        // 加载完成后注入 JavaScript 拦截链接点击
        onLoadingChanged: function(loadRequest) {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                webPreview.loadState = 2  // 加载成功
                // 注入 JS：链接点击用本地浏览器打开
                webView.runJavaScript("
                    document.addEventListener('click', function(e) {
                        var link = e.target.closest('a');
                        if (link && link.href && link.href.startsWith('http')) {
                            e.preventDefault();
                            window.open(link.href, '_blank');
                        }
                    }, true);
                ")
            }
            if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                console.log("WebEngine 加载失败:", loadRequest.errorString)
                webPreview.loadState = 3  // 加载失败，显示错误页面
            }
            if (loadRequest.status === WebEngineView.LoadStoppedStatus) {
                if (webPreview.loadState === 1) {
                    webPreview.loadState = 3  // 加载被中断也算失败
                }
            }
        }

        // 渲染进程崩溃保护：避免子进程异常导致主进程崩溃
        onRenderProcessTerminated: function(terminationStatus, exitCode) {
            console.log("WebEngine 渲染进程异常终止, status:", terminationStatus, "exitCode:", exitCode)
            webPreview.loadState = 3
        }
    }

    // 加载超时保护（30秒）
    Timer {
        id: loadTimeout
        interval: 30000
        running: webPreview.loadState === 1
        onTriggered: {
            if (webPreview.loadState === 1) {
                console.log("WebEngine 加载超时")
                webPreview.loadState = 3
            }
        }
    }

    // 快捷键
    Shortcut {
        sequence: "Escape"
        onActivated: webPreview.close()
    }
    Shortcut {
        sequence: "F5"
        onActivated: {
            webPreview.loadState = 1
            webView.reload()
        }
    }

    // 窗口拖动（工具栏区域）- 使用 mousePosition 单例
    MouseArea {
        id: dragArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        property var clickPos
        acceptedButtons: Qt.LeftButton

        onPressed: function(mouse) {
            if (pressed) {
                clickPos = { x: mouse.x, y: mouse.y }
                dragArea.forceActiveFocus()
            }
        }
        onPositionChanged: {
            if (pressed) {
                webPreview.x = mousePosition.cursorPos().x - clickPos.x
                webPreview.y = mousePosition.cursorPos().y - clickPos.y
            }
        }
    }
}
