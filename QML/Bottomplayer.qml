import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtMultimedia
import QtQuick.Layouts
import "control"
//底部播放器，保证切换页面也不会打断asmr的播放
Item{
    id:root
    implicitHeight: playbackController.bottomplayerHeight
    property alias exposedMediaPlayer: mediaPlayer
    Item{
        anchors.fill: parent
        Rectangle{
            color: root.fullscreen?theme.contentColor:"#00000000"
            anchors.fill: parent
        }
        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            visible: mediaPlayer.mediaStatus > 0
        }
    }
     
	

    // 鼠标活动监听：只作用于右侧容器（视频+控制区）
    // Bottomplayer.qml 中的 MouseArea 部分
    MouseArea {
        id: activityListener
        //visible:false
        anchors.fill: parent  // 关键：锚点始终跟随父组件（高度变化时自动同步）
        z: 10  // 提高层级，避免被其他组件遮挡
        //propagateComposedEvents: true
        hoverEnabled: true

        property bool inactiveMouse: false
         // 播放控制区：在视频区下方（或覆盖在视频区底部）
        PlaybackControl {
            id: playbackController
            anchors.bottom: parent.bottom // 控制区靠底部
            anchors.left: parent.left
            anchors.right: parent.right // 控制区宽度 = 右侧容器宽度
            height: implicitHeight // 用自身默认高度（168/208）
            z: 10 // 层级高于 VideoOutput，确保能看到
        
            // 原有属性绑定，不变
            property bool showControls: !activityListener.inactiveMouse || busy
            opacity: showControls
            onShowControlsChanged: activityListener.cursorShape = showControls ? Qt.ArrowCursor : Qt.BlankCursor
            mediaPlayer: mediaPlayer
            audioTracksInfo: audioTracksInfo
            videoTracksInfo: videoTracksInfo
            subtitleTracksInfo: subtitleTracksInfo
            metadataInfo: metadataInfo
        }
        Timer {
            id: timer
            interval: 1500
            onTriggered: activityListener.inactiveMouse = true
        }

        function activityHandler(mouse) {
            if (activityListener.inactiveMouse)
                activityListener.inactiveMouse = false
            timer.restart()  // 重置定时器
            mouse.accepted = false
        }

        // 补充鼠标移动事件（原代码仅监听 positionChanged/pressed，补充 mousemove 确保覆盖）
        onPositionChanged: mouse => activityHandler(mouse)
        onPressed: mouse => activityHandler(mouse)
        onEntered: {  // 新增：鼠标进入时强制重置状态
            inactiveMouse = false
            timer.restart()
        }
        onExited: {  // 新增：鼠标离开时重置状态
            inactiveMouse = true
        }
        onDoubleClicked: mouse => mouse.accepted = false

        // 监听 bottomplayerHeight 变化，强制重置状态
        Connections {
            target: playbackController
            function onBottomplayerHeightChanged() {
                activityListener.inactiveMouse = false  // 高度变化时重置不活跃状态
                timer.restart()        // 重启定时器
                activityListener.forceActiveFocus()  // 强制获取焦点
            }
        }
    }
    MessageDialog {
        id: mediaError
        buttons: MessageDialog.Ok
    }
    MetadataInfo {
        id: metadataInfo
    }

    TracksInfo {
        id: audioTracksInfo
        onSelectedTrackChanged: {
            mediaPlayer.activeAudioTrack = selectedTrack
            mediaPlayer.updateMetadata()
        }
    }

    TracksInfo {
        id: videoTracksInfo
        onSelectedTrackChanged: {
            mediaPlayer.activeVideoTrack = selectedTrack
            mediaPlayer.updateMetadata()
        }
    }

    TracksInfo {
        id: subtitleTracksInfo
        onSelectedTrackChanged: {
            mediaPlayer.activeSubtitleTrack = selectedTrack
            mediaPlayer.updateMetadata()
        }
    }

    MediaDevices {
        id: mediaDevices
        onAudioOutputsChanged: {
            audio.device = mediaDevices.defaultAudioOutput
        }
    }

    // 播放器主体
    MediaPlayer {
        id: mediaPlayer
        //! [1]
        function updateMetadata() {
            metadataInfo.clear()
            metadataInfo.read(mediaPlayer.metaData)
            metadataInfo.read(mediaPlayer.audioTracks[mediaPlayer.activeAudioTrack])
            metadataInfo.read(mediaPlayer.videoTracks[mediaPlayer.activeVideoTrack])
            metadataInfo.read(mediaPlayer.subtitleTracks[mediaPlayer.activeSubtitleTrack])
        }
        //todo
        videoOutput: videoOutput
        audioOutput: AudioOutput {
            id: audio
            muted: playbackController.muted
            volume: playbackController.volume
        }
        //! [2]
        //! [4]
        onErrorOccurred: {
            mediaError.text = mediaPlayer.errorString
            //mediaError.open()//音频出错的提示，暂时关闭
        }
        //! [4]
        onMetaDataChanged: { updateMetadata() }
        //! [6]
        onTracksChanged: {
            audioTracksInfo.read(mediaPlayer.audioTracks)
            videoTracksInfo.read(mediaPlayer.videoTracks)
            subtitleTracksInfo.read(mediaPlayer.subtitleTracks, 6) /* QMediaMetaData::Language = 6 */
            updateMetadata()
            mediaPlayer.play()
        }
        onPlaybackStateChanged:{
            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                const pos = Math.min(mediaPlayer.duration,mediaPlayer.position + 10)
                mediaPlayer.setPosition(pos)
            }
        }   
        //! [6]
        //source: new URL("https://download.qt.io/learning/videos/media-player-example/Qt_LogoMergeEffect.mp4")
    }
}