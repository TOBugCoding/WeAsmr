// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs
import QtQuick.Controls.Basic
import "../"
Item {
    id: playbackController

    required property MediaPlayer mediaPlayer
    required property MetadataInfo metadataInfo
    required property TracksInfo audioTracksInfo
    required property TracksInfo videoTracksInfo
    required property TracksInfo subtitleTracksInfo
    property alias muted: audioControl.muted
    property alias volume: audioControl.volume
    //监听主界面高度 如果处于全屏就同步
    property var mainheight:mainWindow.contentItem.height
    onMainheightChanged:{
        if(topbar.fullscreen){playbackController.bottomplayerHeight=mainWindow.contentItem.height}
    }
    // 取消横屏/竖屏布局切换（简化逻辑，保持统一紧凑布局）
    property bool landscapePlaybackControls: true // 强制横屏布局（更适合底部固定显示）
    property bool busy: fileDialog.visible
                        || urlPopup.visible
                        || settingsPopup.visible
                        || audioControl.busy
                        || playbackSeekControl.busy

    // 紧凑化高度（适配底部固定显示）
    implicitHeight: 100 // 原 168/208 → 大幅压缩，适合底部常驻
    property var bottomplayerHeight:100
    Behavior on opacity { NumberAnimation { duration: 300 } }

    FileDialog {
        id: fileDialog
        title: "Please choose a file"
        onAccepted: {
            playbackController.mediaPlayer.stop()
            playbackController.mediaPlayer.source = fileDialog.selectedFile
            playbackController.mediaPlayer.play()
        }
    }

    UrlPopup {
        id: urlPopup
        anchors.centerIn: Overlay.overlay
        mediaPlayer: playbackController.mediaPlayer
    }

    SettingsPopup {
        id: settingsPopup
        anchors.centerIn: Overlay.overlay
        metadataInfo: playbackController.metadataInfo
        mediaPlayer: playbackController.mediaPlayer
        audioTracksInfo: playbackController.audioTracksInfo
        videoTracksInfo: playbackController.videoTracksInfo
        subtitleTracksInfo: playbackController.subtitleTracksInfo
    }
   
    // 紧凑化自定义按钮（缩小尺寸，节省空间）
    component CustomButton: Button {
        implicitWidth: 36
        implicitHeight: 36
        //radius: 4
        icon.width: 32
        icon.height: 32
        flat: true
        background: Rectangle {
            color: "transparent" // 透明背景，屏蔽原生选中态白底
            MouseArea{
                anchors.fill:parent
                hoverEnabled:true
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    component CustomRoundButton: Button {
        property int diameter: 36
        Layout.preferredWidth: diameter
        Layout.preferredHeight: diameter
        //radius: diameter / 2
        icon.width: 36
        icon.height: 36
        flat: true
        background: Rectangle {
            color: "transparent" // 透明背景，屏蔽原生选中态白底
            MouseArea{
                anchors.fill:parent
                hoverEnabled:true
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    // 移除全屏按钮（按需求删除）
    // 保留必要按钮：文件选择、URL输入、循环、设置
    CustomButton {
        id: fileDialogButton;
        icon.source: "../images/本地加载.svg";
        icon.color:theme.fontColor;
        onClicked: fileDialog.open();
    }

    CustomButton {
        id: openUrlButton
        icon.source: "../images/连接.svg"
        icon.color:theme.fontColor
        onClicked: urlPopup.open()
    }

    CustomButton {
        id: loopButton
        icon.source: "../images/loop.svg"
        icon.color: playbackController.mediaPlayer.loops === MediaPlayer.Once ? theme.fontColor : theme.green
        onClicked: playbackController.mediaPlayer.loops = playbackController.mediaPlayer.loops === MediaPlayer.Once
                   ? MediaPlayer.Infinite
                   : MediaPlayer.Once
    }

    //CustomButton {
    //    id: settingsButton
    //    icon.source: "../images/more.svg"
    //    icon.color:theme.fontColor
    //    onClicked: settingsPopup.open()
    //}
    CustomButton {
        id: settingsButton
        icon.source: "../images/全屏.svg"
        icon.color:playbackController.bottomplayerHeight==mainWindow.contentItem.height?theme.green:theme.fontColor
        onClicked: {
            //全屏状态
            if( playbackController.bottomplayerHeight==mainWindow.contentItem.height){ //| playbackController.mediaPlayer.mediaStatus <= 0 ){
                //发现顶部栏存在则隐藏
                if(topbar.opacity==1){topbar.opacity=0;return;}
                topbar.opacity=0
                playbackController.bottomplayerHeight=100
                topbar.fullscreen=false
            }else{
                playbackController.bottomplayerHeight=mainWindow.contentItem.height
                topbar.fullscreen=true
                topbar.opacity=1
            }
        }
    }
    // 控制按钮行（紧凑化间距）
    RowLayout {
        id: controlButtons
        spacing: 8 // 原 16 → 减半，紧凑排列
        CustomRoundButton {
            id: backward10Button
            icon.source: "../images/backward10.svg"
            icon.color:theme.fontColor
            onClicked: {
                const pos = Math.max(0, playbackController.mediaPlayer.position - 10000)
                playbackController.mediaPlayer.setPosition(pos)
            }
        }

        CustomRoundButton {
            id: playButton
            visible: playbackController.mediaPlayer.playbackState !== MediaPlayer.PlayingState
            icon.source: "../images/play_symbol.svg"
            icon.color:theme.fontColor
            onClicked: playbackController.mediaPlayer.play()
        }

        CustomRoundButton {
            id: pauseButton
            visible: playbackController.mediaPlayer.playbackState === MediaPlayer.PlayingState
            icon.source: "../images/pause_symbol.svg"
            icon.color:theme.fontColor
            onClicked: playbackController.mediaPlayer.pause()
        }

        CustomRoundButton {
            id: forward10Button
            icon.source: "../images/forward10.svg"
            icon.color:theme.fontColor
            onClicked: {
                const pos = Math.min(playbackController.mediaPlayer.duration,
                                   playbackController.mediaPlayer.position + 10000)
                playbackController.mediaPlayer.setPosition(pos)
            }
        }
    } // RowLayout controlButtons

    // 音量条：强制显示（去掉原 showSlider 的宽度判断）
    AudioControl {
        id: audioControl
        showSlider: true // 原 root.width >= 960 → 改为 true，永远显示音量条
    }

    // 进度条：永远显示，保持填充宽度
    PlaybackSeekControl {
        id: playbackSeekControl
        Layout.fillWidth: true
        mediaPlayer: playbackController.mediaPlayer
    }

    // 主布局（强制横屏，紧凑化内边距和间距）
    Rectangle {
        id: mainLayout
        anchors.fill: parent
        anchors.margins:12
        anchors.topMargin: 8 // 原 28 → 压缩顶部空白
        visible: true // 强制显示，取消竖屏布局切换
        color:"#00000000"
        ColumnLayout {
            anchors.fill: parent
            spacing: 6 // 原 16 → 大幅压缩垂直间距
            // 第一行：功能按钮 + 控制按钮 + 音量条
            Item {
                Layout.fillWidth: true
                implicitHeight: 36 // 紧凑化行高

                LayoutItemProxy {
                    id: fdbProxy
                    target: fileDialogButton
                    anchors.left: parent.left
                }

                LayoutItemProxy {
                    target: openUrlButton
                    anchors.left: fdbProxy.right
                    anchors.leftMargin: 6 // 原 12 → 缩小边距
                }

                LayoutItemProxy {
                    target: controlButtons
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                LayoutItemProxy {
                    target: loopButton
                    anchors.right: acProxy.left
                    anchors.verticalCenter:acProxy.verticalCenter
                    anchors.rightMargin: 6 // 原 12 → 缩小边距
                }

                LayoutItemProxy {
                    id: acProxy
                    target: audioControl
                    anchors.right: parent.right
                    anchors.rightMargin: 30 // 取消右边距，紧凑显示
                    //anchors.left: fdbProxy.right
                    //anchors.leftMargin: 500 // 原 30 → 大幅缩小边距
                    anchors.verticalCenter: parent.verticalCenter
                }

                LayoutItemProxy {
                    id: sbProxy
                    target: settingsButton
                    anchors.right: parent.right
                    anchors.rightMargin: 0 // 取消右边距，紧凑显示
                }
            } // Item

            // 第二行：进度条（永远显示，缩小上下边距）
            LayoutItemProxy {
                target: playbackSeekControl
                Layout.topMargin: 4 // 原 16 → 缩小
                Layout.bottomMargin: 4 // 原 16 → 缩小
                Layout.fillWidth: true
            }
        }
    } // Frame mainLayout

    // 移除竖屏布局（portraitLayout）：因强制横屏，无需保留
}