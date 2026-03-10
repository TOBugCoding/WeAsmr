import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QuickVLC
import QtQuick.Controls.Basic
Item {
    id: seekController
    required property MediaPlayer mediaPlayer
    property alias busy: slider.pressed
    property alias color_slider:silider_bg.opacity
    implicitHeight: 20

    function formatToMinutes(milliseconds) {
        if (!milliseconds || milliseconds < 0) {
            milliseconds = 0;
        }
        const min = Math.floor(milliseconds / 60000);
        const sec = Math.floor((milliseconds - min * 60000) / 1000);
        return `${min}:${sec.toString().padStart(2, 0)}`;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 22

        
        Text {
            id: currentTime
            Layout.preferredWidth: 45
            text: seekController.formatToMinutes(seekController.mediaPlayer.position)
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 11
            color:theme.fontColor
        }
        

        Slider {
            id: slider
            Layout.fillWidth: true
            implicitHeight: 21
            enabled: seekController.mediaPlayer.seekable
            value: (pressed||mediaPlayer.loading.visible)?visualPosition:(seekController.mediaPlayer.position / seekController.mediaPlayer.duration)
            onPressedChanged: {
                if (!pressed && seekController.mediaPlayer.duration > 0) {
                    seekController.mediaPlayer.position = visualPosition * seekController.mediaPlayer.duration
                    mediaPlayer.loading.visible = true
                }
            }
            leftPadding: 0
            rightPadding: 0
            Component.onCompleted: {
                console.log("leftpa"+slider.leftPadding)
                console.log("rigtpa"+slider.rightPadding)
            }

            snapMode: Slider.SnapOnRelease
            handle: Rectangle {
                opacity: 0  // 视觉隐藏handle，替代宽高设0
            }
            background: Rectangle {
                id: silider_bg
                height: slider.availableHeight
                width: slider.availableWidth
                radius: 10
                color: "gray"
                opacity: theme.opacity
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: sliderMouseArea
                    enabled: seekController.mediaPlayer.seekable
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: null  // 仅监听位置，不实际拖动元素
                    propagateComposedEvents: true  // 事件透传，不影响Slider的pressed状态

                    function updatePreviewTime() {
                        if (seekController.mediaPlayer.duration <= 0) return;
                        let hoverRatio;
                        if (slider.pressed) {
                            hoverRatio = slider.visualPosition;
                        }
                        //如果是hover状态，用鼠标坐标
                        else {
                            hoverRatio = Math.max(0, Math.min(1, (mouseX) / (slider.width)));
                        }
                        const targetMs = hoverRatio * seekController.mediaPlayer.duration;
                        currentTime.text = seekController.formatToMinutes(targetMs);
                        currentTime.color = theme.green;
                    }

                    // hover时更新
                    onPositionChanged: updatePreviewTime();
                    // 拖动时（Slider的visualPosition变化）也更新
                    Connections {
                        target: slider
                        function onVisualPositionChanged() {
                            if (slider.pressed) { // 仅拖动时更新
                                sliderMouseArea.updatePreviewTime();
                            }
                        }
                    }

                    // 离开hover/结束拖动时恢复原时间
                    onExited: {
                        currentTime.text = Qt.binding(function() {
                            return seekController.formatToMinutes(seekController.mediaPlayer.position)
                        });
                        currentTime.color = Qt.binding(function() { return theme.fontColor });
                    }
                }

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: theme.green
                    radius: 10
                }
            }
        }

       
        Text {
            id: remainingTime
            Layout.preferredWidth: 45
            text: seekController.formatToMinutes(seekController.mediaPlayer.duration)
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 11
            color:theme.fontColor
        }
      
    }
}
