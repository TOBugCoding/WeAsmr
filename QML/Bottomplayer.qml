import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QuickVLC
import QtQuick.Layouts
import com.asmr.player 1.0
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
            id: output
            anchors.fill: parent
            source: mediaPlayer
            z:1
        }
    }
     
	

    // 鼠标活动监听：只作用于右侧容器（视频+控制区）
    // Bottomplayer.qml 中的 MouseArea 部分
    MouseArea {
        focus: true
        activeFocusOnTab: true
        id: activityListener
        anchors.fill: parent
        z: 10  // 提高层级，避免被其他组件遮挡
        hoverEnabled: true
        onInactiveMouseChanged: {
            if(!topbar.fullscreen){
                activityListener.inactiveMouse = false
            }
        }
        property bool inactiveMouse: false
         // 播放控制区：在视频区下方（或覆盖在视频区底部）
        PlaybackControl {
            id: playbackController
            anchors.bottom: parent.bottom // 控制区靠底部
            anchors.left: parent.left
            anchors.right: parent.right // 控制区宽度 = 右侧容器宽度
            height: implicitHeight // 用自身默认高度（168/208）
            z: 10 // 层级高于 VideoOutput，确保能看到

            property bool showControls: !activityListener.inactiveMouse || busy
            opacity: showControls
            onShowControlsChanged: activityListener.cursorShape = showControls ? Qt.ArrowCursor : Qt.BlankCursor
            mediaPlayer: mediaPlayer
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

        onPositionChanged: mouse => activityHandler(mouse)
        onPressed: function(mouse){
            activityHandler(mouse)
            if(playbackController.mediaPlayer.playbackState !==2){
                playbackController.mediaPlayer.play()
            }else{
                playbackController.mediaPlayer.pause();
            }

        }
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
    Shortcut {
          sequence:"space"  // 绑定空格键
          // context: Shortcut.ApplicationShortcut  // 可选：整个应用内全局
          onActivated: {
              if (mediaPlayer.playbackState ===2) {
                  mediaPlayer.pause()
              } else {
                  mediaPlayer.play()
              }
          }
      }

      Shortcut {
          sequence: "left"
          onActivated: {
              const pos = Math.max(0, mediaPlayer.position - 10000)
              mediaPlayer.position = pos
          }
      }

      Shortcut {
          sequence: "right"
          onActivated: {
              const pos = Math.min(mediaPlayer.duration, mediaPlayer.position + 10000)
              mediaPlayer.position = pos

          }
          // 可选：动态禁用（如视频未加载完成时）
          // enabled: mediaPlayer.duration > 0
      }

    // 播放器主体
    MediaPlayer {
        id: mediaPlayer
        audioOutput: audioOutput
        onPlaybackStateChanged:{
            console.log("播放状态："+mediaPlayer.playbackState)
            if(mediaPlayer.playbackState===4){
                if(playbackController.loop){
                    reload_audio();
                }else{
                    next_audio_play();
                }

            }
        }
        //当分辨率变化时
        onErrorOccurred: {
            console.log("错误"+errorString)
        }
    }
    AudioOutput {
        id: audioOutput
        volume: playbackController.volume
        muted: playbackController.muted
    }
    function next_audio_play(){
        let path=ASMRPlayer.get_audioName()
        if(path!==""){
            //设置下一个播放源
            ASMRPlayer.get_sign_path(path);
        }
    }
    function reload_audio(){
        let path = ASMRPlayer.get_current_playing()
        ASMRPlayer.get_sign_path(path);
    }
    Connections {
        target: ASMRPlayer
        function onSignPathReceived(path){
            if(path.toString().includes(".m3u8")){
                output.visible = true
            } else {
               output.visible = false
            }
            mediaPlayer.source = path
        }
        function onDownloadPathReceived(path){
            //执行下载任务
            dowloadmgr.addDownloadTask(path);
            //下载完成由leftbar中的消息框进行提示
        }
        function onEmptyM3u8(path){
            dowloadmgr.addDownloadTask(path,false,true);
        }
    }
    Connections{
        target: dowloadmgr
        function onM3u8Content(content){
            mediaPlayer.source = content
            output.visible = true
            console.log("视频")
            //console.log(content)
        }
    }
}
