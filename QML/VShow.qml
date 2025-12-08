import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Window
import ffmpegAudioThread
Item {                 // 根节点只当容器，不依赖任何窗口
    id: root
    anchors.fill: parent
    /* =========  通用工具  ========= */
    function formatTime(ms) {
        const s = Math.floor(ms / 1000);
        const m = Math.floor(s / 60);
        const h = Math.floor(m / 60);
        return [h, m % 60, s % 60]
               .map(v => v.toString().padStart(2, '0'))
               .join(':');
    }

    /* =========  文件选择  ========= */
    FileDialog {
        id: fileDlg
        onAccepted: {
            const path = selectedFile.toString().replace('file:///', '');
            if (videoPlayer.loadFile(path)) {
                videoPlayer.play();
            }
        }
    }

    /* =========  主行布局：视频 90% + 侧边 10%  ========= */
    Row {
        anchors.fill: parent
        spacing: 10

        /* ----------------  视频区域  ---------------- */
        VideoPlayer {
            id: videoPlayer
            width: parent.width * 0.9
            height: parent.height

            onDurationChanged: function(duration){   // ← 显式
                slider.to = duration;
            }
            onPositionChanged: function(position){
                if (!slider.pressed) slider.value = position;
            }

            /* 底部进度条 */
            Slider {
                id: slider
                width: videoPlayer.width
                height: 20
                anchors.bottom: parent.bottom
                from: 0; to: videoPlayer.duration; value: videoPlayer.position
                opacity: 0
                onValueChanged: function(value) {
                    if (pressed) videoPlayer.setPosi(Math.floor(value));
                }

           
                /* 鼠标悬停显隐 */
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:  slider.opacity = 1;
                    onExited:   slider.opacity = 0;
                    onClicked: function(mouse){
                        const ratio = mouse.x / width;
                        slider.value = slider.from + ratio * (slider.to - slider.from);
                        videoPlayer.setPosi(Math.floor(slider.value));
                    }
                }

                /* 时间标签 */
                Label {
                    id: timeLbl
                    color: 'white'
                    text: formatTime(slider.value)
                    x: slider.leftPadding + slider.visualPosition * (slider.width - width)
                    y: slider.topPadding - height
                }
            }
        }

        /* ----------------  右侧控制列  ---------------- */
        Column {
            width: parent.width * 0.1
            height: parent.height
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter

            Button { text: '开始';  onClicked: fileDlg.open() }
            Button { text: '暂停';  onClicked: videoPlayer.pause() }

            Slider {                                 // 倍速
                id: speedSlider
                orientation: Qt.Vertical
                from: 0.5; to: 2.0; value: 1.0; stepSize: 0.1
                onValueChanged:function(value) {
                    videoPlayer.audioSpeed(value.toFixed(1));
                    speedLbl.text = '速度:' + value.toFixed(1);
                }
            }
            Label {
                id: speedLbl
                color: 'white'
                text: '速度:1.0'
            }
        }
    }
    Component.onDestruction: {
        console.log("播放器页面即将被销毁，释放资源...");
        // 1. 停止播放
        videoPlayer.stop();
        // 2. 清空加载的文件（释放底层音视频资源）
        videoPlayer.loadFile("");
        // 3. 如果有C++对象（如FFmpeg线程），显式通知释放
        if (videoPlayer.audioThread) {
            videoPlayer.audioThread.stop(); // 停止线程
            videoPlayer.audioThread = null; // 断开引用，帮助GC
        }
    }
}