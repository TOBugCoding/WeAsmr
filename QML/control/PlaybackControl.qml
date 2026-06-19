// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QuickVLC
import QtQuick.Dialogs
import QtQuick.Controls.Basic
import QtQuick.Effects
import "../"
import "../components/MediaUtils.js" as MediaUtils
import com.asmr.player 1.0
Item {
    id: playbackController

    required property MediaPlayer mediaPlayer
    required property VideoOutput output
    required property AudioOutput audioOutput
    property alias muted: audioControl.muted
    property alias volume: audioControl.volume
    property alias loop: loopButton.loops
    property alias slider_bg:playbackSeekControl.color_slider
    // 监听主界面高度 如果处于全屏就同步
    property int mainheight: mainWindow.contentItem.height
    onMainheightChanged: {
        if (topbar.fullscreen) {
            playbackController.bottomplayerHeight = mainWindow.contentItem.height
        }
    }

    // 取消横屏/竖屏布局切换（简化逻辑，保持统一紧凑布局）
    property bool landscapePlaybackControls: true // 强制横屏布局（更适合底部固定显示）
    property bool busy: fileDialog.visible
                        || urlPopup.visible
                        || audioControl.busy
                        || playbackSeekControl.busy

    // 紧凑化高度（适配底部固定显示）
    implicitHeight: 120
    property int bottomplayerHeight: 100
    property string currentCollectFile:""
    Connections {
           target: ASMRPlayer
           function onCollect_file_changed(){playbackController.currentCollectFile=ASMRPlayer.get_collect_file()}
    }
    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: "选择要加载的音频资源"
        currentFolder: "file:///" + appDir + "/download"

        onAccepted: {
            var fileUrl = fileDialog.selectedFile.toString()
            var fileName = fileUrl.substring(fileUrl.lastIndexOf("/") + 1)

            // 判断是否是音视频文件（非音视频文件走预览）
            var isMedia = MediaUtils.isMediaFile(fileName)

            // 非音视频文件：使用系统默认程序打开
            if (!isMedia) {
                Qt.openUrlExternally(fileDialog.selectedFile)
                return
            }

            // 音视频文件：播放
            let suc=playbackController.mediaPlayer.setSafeUrl(fileDialog.selectedFile,true)
            if(!suc){
                return;
            }
            systemIcon.tooltip = fileName
            audioOutput.volume = Qt.binding(function() { return playbackController.volume })
            var isVideo = MediaUtils.isVideoFile(fileUrl)
            if (isVideo) {
                output.visible = true
                playbackController.slider_bg=0
                console.log("视频播放")
            } else {
                playbackController.slider_bg=theme.opacity
                output.visible = false
                console.log("音频播放")
            }
        }
    }

    UrlPopup {
        id: urlPopup
        anchors.centerIn: Overlay.overlay
        mediaPlayer: playbackController.mediaPlayer
        onClosed: {
            output.visible = true
        }
    }

    // 收藏夹选择弹窗
    SelectCollect {
        id: selectCollect
        parent: Overlay.overlay
    }

    // 紧凑化自定义按钮（缩小尺寸，节省空间）
    component CustomButton: Button {
        implicitWidth: 36
        implicitHeight: 36
        icon.width: 32
        icon.height: 32
        flat: true

        background: Rectangle {
            color: "transparent"
        }
    }

    component CustomRoundButton: Button {
        property int diameter: 36
        Layout.preferredWidth: diameter
        Layout.preferredHeight: diameter
        icon.width: 36
        icon.height: 36
        flat: true

        background: Rectangle {
            color: "transparent"
        }
    }

    // 主布局（强制横屏，紧凑化内边距和间距）
    Rectangle {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 8
        visible: true
        color: "#00000000"

        ColumnLayout {
            anchors.fill: parent
            spacing: 2

            // 进度条
            PlaybackSeekControl {
                id: playbackSeekControl
                Layout.fillWidth: true
                mediaPlayer: playbackController.mediaPlayer
            }

            // 控制按钮行
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 36

                // 左侧：功能按钮组
                RowLayout {
                    id: leftButtons
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    HoverButton {
                        id: fileDialogButton
                        image_path: "qrc:/sources/image/本地加载.svg"
                        onClicked: fileDialog.open()
                    }

                    HoverButton {
                        id: openUrlButton
                        image_path: "qrc:/sources/image/连接.svg"
                        onClicked: urlPopup.open()
                    }

                    // 喜欢按钮
                    Item {
                        id: likeButton
                        width: 36
                        height: 36
                        property bool isLiked: false
                        property string currentAudio: ""

                        Component.onCompleted: {
                            currentAudio = ASMRPlayer.get_current_playing()
                            updateLikedState()
                        }

                        function updateLikedState() {
                            if (currentAudio && currentAudio !== "") {
                                isLiked = ASMRPlayer.isLiked(currentAudio)
                            } else {
                                isLiked = false
                            }
                        }

                        // 监听喜欢状态变化信号
                        Connections {
                            target: ASMRPlayer
                            function onLikedChanged() {
                                likeButton.updateLikedState()
                            }
                            function onCurrent_playing_changed() {
                                likeButton.currentAudio = ASMRPlayer.get_current_playing()
                                likeButton.updateLikedState()
                            }
                        }

                        Image {
                            id: likeIcon
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: "qrc:/sources/image/我喜欢的.svg"
                            visible: false
                            mipmap: true
                            smooth: true
                        }
                        MultiEffect {
                            source: likeIcon
                            anchors.fill: likeIcon
                            brightness: likeButton.isLiked ? 1 : (likeMouseArea.containsMouse ? 1 : theme.globalBrightness)
                            colorization: likeButton.isLiked ? 1 : (likeMouseArea.containsMouse ? 0.5 : 0)
                            colorizationColor: likeButton.isLiked ? "#FF4444" : theme.globalColor
                        }

                        MouseArea {
                            id: likeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var currentPlaying = ASMRPlayer.get_current_playing()
                                if (currentPlaying && currentPlaying !== "") {
                                    ASMRPlayer.toggleLike(currentPlaying)
                                }
                            }
                        }
                    }
                    Column{
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4
                        Row{
                            visible: currentCollectFile!==""
                            spacing: 4
                            Text {
                                text: qsTr("播放列表:")
                                color:theme.green
                            }
                            Text {
                                width:150
                                text:currentCollectFile
                                color:theme.fontColor
                                elide: Text.ElideMiddle
                            }
                        }
                        Row{
                            visible: systemIcon.tooltip!==systemIcon.appName
                            spacing: 4
                            Text{
                                text: qsTr("当前音频:")
                                color:theme.green
                            }
                            Text {
                                width:150
                                text:systemIcon.tooltip.split("/").pop();
                                color:theme.fontColor
                                elide: Text.ElideMiddle
                            }
                        }

                    }

                }


                // 右侧：音频和设置按钮组
                RowLayout {
                    id: rightButtons
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    //播放暂停
                    HoverButton {
                        id: playButton
                        visible: (playbackController.mediaPlayer.playbackState !== 2) ||
                                (playbackController.mediaPlayer.pauseAnim.running)
                        image_path: "qrc:/sources/image/play_symbol.svg"
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: {
                            playbackController.mediaPlayer.playAnim.start()
                        }
                    }
                    HoverButton {
                        id: pauseButton
                        visible: !playButton.visible
                        image_path: "qrc:/sources/image/pause_symbol.svg"
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: {
                            playbackController.mediaPlayer.pauseAnim.start()
                        }
                    }
                    // 循环按钮
                    CustomButton {
                        property bool loops: false
                        id: loopButton
                        icon.source: "qrc:/sources/image/loop.svg"
                        icon.color: loops ? theme.green : theme.fontColor
                        onClicked: loops = !loops
                        implicitWidth: 36
                        implicitHeight: 36
                    }

                    // 音量控制
                    AudioControl {
                        id: audioControl
                        showSlider: true
                        height: 36
                    }

                    // 全屏按钮
                    HoverButton {
                        id: settingsButton
                        image_path: "qrc:/sources/image/全屏.svg"
                        implicitWidth: 22
                        implicitHeight: 22
                        onClicked: {
                            //取消全屏
                            if (playbackController.bottomplayerHeight === mainWindow.contentItem.height) {
                                if (topbar.opacity === 1) {
                                    topbar.opacity = 0
                                    return
                                }
                                topbar.opacity = 0
                                playbackController.bottomplayerHeight = 100
                                topbar.fullscreen = false
                            }
                            //执行全屏
                            else {
                                playbackController.bottomplayerHeight = mainWindow.contentItem.height
                                topbar.fullscreen = true
                                topbar.opacity = 0
                            }
                        }
                    }
                }
            }
        }
    }
}
