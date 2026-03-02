import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QuickVLC
import QtQuick.Layouts
import com.asmr.player 1.0
import "control"
import "components"
//底部播放器，保证切换页面也不会打断asmr的播放
Item{
    id:root
    implicitHeight: playbackController.bottomplayerHeight
    property alias exposedMediaPlayer: mediaPlayer
    function updateCurrentLrc() {
        if (lrcModel.count === 0) return;

        const currentTime = mediaPlayer.position;
        let targetIndex = 0;

        // 找到当前时间最匹配的歌词行
        for (let i = 0; i < lrcModel.count; i++) {
            const lrcTime = lrcModel.get(i).startTime;
            if (lrcTime <= currentTime) {
                targetIndex = i;
            } else {
                break;
            }
        }

        // 修复：计算正确的滚动位置
        const itemHeight = 30; // 每行歌词高度
        const visibleHeight = lrcListView.height;
        const contentHeight = lrcModel.count * itemHeight;

        // 计算目标位置，确保当前歌词在中间
        let targetY = targetIndex * itemHeight - visibleHeight/2 + itemHeight/2;

        // 边界检查：确保不会滚动到超出范围
        targetY = Math.max(0, Math.min(targetY, contentHeight - visibleHeight));

        lrcListView.contentY = targetY;
    }
    NumberAnimation{
        id:resumeAnim
        target: audioOutput
        property: "volume"
        from: 0
        to:playbackController.volume
        duration: 500
        easing.type: Easing.InQuad
        onStarted: {
            pauseAnim.stop()
            mediaPlayer.play()
        }
        onStopped: {
            //audioOutput.volume=Qt.binding(function() { return playbackController.volume })
        }
    }
    NumberAnimation{
        id:pauseAnim
        target: audioOutput
        property: "volume"
        from: playbackController.volume
        to:0
        duration: 500
        easing.type: Easing.InQuad
        onStarted: {
            resumeAnim.stop()
        }
        onStopped: {
            mediaPlayer.pause()
            //audioOutput.volume=Qt.binding(function() { return playbackController.volume })
        }
    }
    Item{
        id:video_parent
        anchors.fill: parent

        Rectangle{
            color: topbar.fullscreen?theme.contentColor:"#00000000"
            anchors.fill: parent

        }
        VideoOutput {
            id: output
            anchors.left:parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: topbar.fullscreen?parent.height:parent.height-10
            Behavior on height {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            source: mediaPlayer
            z:1
            visible: false
        }
        ListModel {
                id: lrcModel
        }
        ListView {
                id: lrcListView
                anchors.left: parent.left
                anchors.right: parent.right
                //anchors.verticalCenter: parent.verticalCenter
                height: topbar.fullscreen?parent.height * 0.6:parent.height * 0.5  // 占父容器60%高度
                y: topbar.fullscreen?parent.height * 0.2:parent.height * 0.3

                // 关闭手动滚动
                interactive: false
                model: lrcModel
                orientation: ListView.Vertical
                highlightRangeMode: ListView.ApplyRange
                flickDeceleration: 1000
                boundsBehavior: Flickable.StopAtBounds
                Behavior on contentY {
                    NumberAnimation {
                        duration: 300  // 动画时长300ms
                        easing.type: Easing.InOutQuad  // 先慢后快再慢的缓动曲线
                    }
                }
                // 歌词项委托（样式不变，优化高亮逻辑）
                delegate: Item {
                    width: lrcListView.width
                    height: 30  // 每行高度固定

                    Text {
                        id: lrcText
                        anchors.centerIn: parent
                        text: model.lrcContent  // 匹配C++解析的字段名（lrcContent）
                        font.pixelSize: 21
                        // 优化高亮逻辑：当前行时间 ≤ 播放进度 且 下一行时间 > 播放进度
                        color: isCurrentLrc ? theme.green : theme.fontColor
                        font.bold: isCurrentLrc
                        horizontalAlignment: Text.AlignHCenter

                        // 标记是否为当前歌词行（简化Delegate内的逻辑）
                        property bool isCurrentLrc: {
                            const currentTime = mediaPlayer.position; // 播放进度（毫秒）
                            const currentLrcTime = model.startTime;  // 歌词时间（毫秒）
                            // 找到当前项的下一项时间
                            const nextIndex = index + 1;
                            const nextLrcTime = nextIndex < lrcModel.count ? lrcModel.get(nextIndex).startTime : Infinity;
                            // 核心判断：当前时间在「当前歌词时间 ~ 下一句歌词时间」区间内
                            return currentTime >= currentLrcTime && currentTime < nextLrcTime;
                        }
                    }
                }

                // 隐藏滚动条
                ScrollBar.vertical: ScrollBar {
                    visible: false
                }
        }

        Item {
            z:2
            id: loadingOverlay
            anchors.fill: parent
            visible: false
            //后续添加加载动画
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
            output:output
            audioOutput:audioOutput
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
            if(!topbar.fullscreen){return}
            if(playbackController.mediaPlayer.playbackState !==2){
                resumeAnim.start()
            }else{
                pauseAnim.start()
            }

        }
        onEntered: {  // 新增：鼠标进入时强制重置状态
            inactiveMouse = false
            timer.restart()
            if(output.visible===true){
                playbackController.slider_bg=theme.opacity
                //output.height=Qt.binding(function() { return topbar.fullscreen?video_parent.height:video_parent.height-30 })
            }
        }
        onExited: {  // 新增：鼠标离开时重置状态
            inactiveMouse = true
            if(output.visible===true){
                playbackController.slider_bg=0
                //output.height=Qt.binding(function() { return topbar.fullscreen?video_parent.height:video_parent.height })
            }
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
    MessageBox {
        id: msg
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
        enabled: mediaPlayer.duration > 0
    }

    Shortcut {
        sequence: "left"
        onActivated: {
            const pos = Math.max(0, mediaPlayer.position - 10000)
            mediaPlayer.position = pos
        }
        enabled: mediaPlayer.duration > 0
      }

    Shortcut {
        sequence: "right"
        onActivated: {
            const pos = Math.min(mediaPlayer.duration, mediaPlayer.position + 10000)
            mediaPlayer.position = pos
        }
        enabled: mediaPlayer.duration > 0
    }

    // 播放器主体
    MediaPlayer {
        property bool lrcshow:true
        property int playNum:0
        property var validMediaFormats: [
                // 音频格式
                "mp3", "wav", "flac", "aac", "ogg", "m4a", "wma",
                // 视频格式
                "mp4", "avi", "mov", "mkv", "flv", "wmv", "mpeg", "mpg","m3u8","ts","3gp"
            ]
        id: mediaPlayer
        audioOutput: audioOutput
        onPlaybackStateChanged:{
            console.log("播放状态："+mediaPlayer.playbackState)
            if(mediaPlayer.playbackState===1){
                loadingOverlay.visible=true
            }
            else if(mediaPlayer.playbackState===2){
                //播放
                mediaPlayer.playNum=0
                loadingOverlay.visible=false
            }
            else if(mediaPlayer.playbackState===3){
                //暂停
            }
            else if(mediaPlayer.playbackState===4){
                //计数position变化小于3次则播放失败
                if(mediaPlayer.playNum<3){
                    msg.set_flag=0;
                    msg.text = "播放失败："+ASMRPlayer.get_current_playing().split("/").pop();
                    msg.image_visible = true;
                    msg.open();
                    output.visible = false
                    mediaPlayer.stop()
                    mediaPlayer.source = ""
                }
                systemIcon.tooltip=systemIcon.appName
                if(playbackController.loop){
                    reload_audio();
                }else{
                    next_audio_play();
                }
            }
        }
        function setSafeUrl(url,local){
            console.log(url)
            if(!url){
                msg.text = "找不到音频源，请切换网站"
                msg.open()
                ASMRPlayer.set_current_playing(systemIcon.tooltip)
                return;
            }
            var sourcePath = url.toString()
            var fileExt = sourcePath.split(".").pop().toLowerCase()
            var purePath = fileExt.split("?")[0];//提取视频格式
            var fileNameWithoutExt = sourcePath.split(".").slice(0, -1).join(".")+".lrc"
            // 检查后缀是否在合法格式列表中
            if (!validMediaFormats.includes(purePath)) {
                console.log("不支持的媒体格式：" + purePath)
                msg.text = "不支持的格式：" + purePath + "，请选择音视频文件"
                msg.open()
                //当前播放切回前面的播放
                ASMRPlayer.set_current_playing(systemIcon.tooltip)
                return false
            }else{
                if(local&&ASMRPlayer.getFileSize(url)<=0){
                    msg.text = "文件大小为0，无法播放"
                    msg.open()
                    ASMRPlayer.set_current_playing(systemIcon.tooltip)
                    return false;
                }
                if(local){
                    lrcListView.visible=false
                    console.log("lrc地址"+fileNameWithoutExt)
                    //添加本地lrc的寻找，找到的话就加载到listmodel
                    ASMRPlayer.getLrc(fileNameWithoutExt);
                }
                mediaPlayer.stop()
                mediaPlayer.source = url
                mediaPlayer.play()
            }
            return true
        }
        onPositionChanged: {
            if(mediaPlayer.playNum<3){
                mediaPlayer.playNum++
            }
            updateCurrentLrc()
        }
        onErrorOccurred: {
            console.log("错误"+errorString)
            mediaError.open(errorString)
        }
        property alias playAnim: resumeAnim
        property alias pauseAnim: pauseAnim
    }
    AudioOutput {
        id: audioOutput
        volume: playbackController.volume
        muted: playbackController.muted
        Component.onCompleted: {
            audioOutput.volume=Qt.binding(function() { return playbackController.volume })
        }
        // onVolumeChanged: {
        //     console.log("音量改变")
        // }

    }
    function next_audio_play(){
        //针对收藏列表的处理
        let path=ASMRPlayer.get_audioName()
        let vlcpath=ASMRPlayer.get_vlcName(path)
        if(path!==""){
            //设置下一个播放源
            ASMRPlayer.get_sign_path(path);
        }
        if(vlcpath!==""){
            ASMRPlayer.download_vlc_path(vlcpath)
        }
    }
    function reload_audio(){
        let path = ASMRPlayer.get_current_playing()
        console.log("重播"+path)
        ASMRPlayer.get_sign_path(path);
    }
    Connections {
        target: ASMRPlayer
        function onSignPathReceived(path){
            let suc
            if(path.startsWith("file:///")){
                //本地路径自带lrc判断
                suc=mediaPlayer.setSafeUrl(path,true)
            }else{
                suc=mediaPlayer.setSafeUrl(path)
                //非本地路径需要判断是否显示lrc
                if(!mediaPlayer.lrcshow){
                    lrcListView.visible=false
                }
            }
            if(!suc){
                return
            }

            audioOutput.volume=playbackController.volume
            if(path.toString().includes(".m3u8")||path.toString().includes(".ts")){
                output.visible = true
                playbackController.slider_bg=0
            } else {
                output.visible = false
                playbackController.slider_bg=theme.opacity
            }
            systemIcon.tooltip=ASMRPlayer.get_current_playing()
            loadingOverlay.visible=true
            audioOutput.volume=Qt.binding(function() { return playbackController.volume })
        }
        function onDownloadPathReceived(path){
            //执行下载任务
            if(!path){
                msg.text = "找不到音频源，请切换网站"
                msg.open()
                return;
            }
            dowloadmgr.addDownloadTask(path);
            //下载完成由leftbar中的消息框进行提示
        }
        function onEmptyM3u8(path){
            if(!path){
                msg.text = "找不到音频源，请切换网站"
                msg.open()
                return;
            }
            dowloadmgr.addDownloadTask(path,false,true);
        }
        function onSigLrcContent(lrcList){
            console.log("收到lrc")
            lrcModel.clear()
            lrcListView.contentY=0
            lrcListView.contentHeight=0
            for (let i = 0; i < lrcList.length; i++) {
                lrcModel.append({ startTime: lrcList[i].startTime,lrcContent: lrcList[i].lrcContent});
            }
            lrcListView.visible=true

        }
        function onSigShowVlc(show){
            mediaPlayer.lrcshow=show
        }
    }
    Connections{
        target: dowloadmgr
        function onM3u8Content(content){
            let suc=mediaPlayer.setSafeUrl(path)
            if(!suc){
                return
            }
            audioOutput.volume=playbackController.volume
            systemIcon.tooltip=ASMRPlayer.get_current_playing()
            output.visible = true
            playbackController.slider_bg=0
            loadingOverlay.visible=true
            //console.log(content)
        }
    }
}
