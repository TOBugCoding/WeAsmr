import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtMultimedia
import FpsCounter
import PageMgr 1.0
import "components" as Components
ApplicationWindow {
    id:mainWindow
    visible: true
    width: now_width;height: now_height
    minimumWidth:720;minimumHeight:480
    //flags:Qt.Window|Qt.FramelessWindowHint|Qt.WindowStaysOnTopHint
    flags:Qt.Window|Qt.FramelessWindowHint
    //管理大小位置的重现
    property var now_width:1080
    property var now_height:600
    property var prev_pos:Qt.vector2d(0,0)
    property var prev_width:now_width
    property var prev_height:now_height
    property var state:-1
    title: ""
    color:"#00000000" //比设置background更高效，并且最好不用transparent，否则要加上Qt.WA_TranslucentBackground
    //background:Rectangle{color:"#00000000"}
    //音频组件 现在改为cpp全局单例注册
	//NetMusic {id: asmr_player}
    //页面缓存管理
    //PageMgr{id:pageMgr}
    FontLoader {
        id: iconFont
        source: "qrc:/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }
    Components.ETheme {
        id: theme
    }
    Components.EAnimatedWindow {
        id: animationWrapper1
        Components.Aboutme {}
    }
    Components.EAlertDialog {
        anchors.fill:parent
        id: exitDialog
        title: "要退出应用吗？"
        message: "退出将关闭所有窗口。"
        cancelText: "取消"
        confirmText: "退出"
        dismissOnOverlay: false
        onConfirm: mainWindow.close()
        focus:true
        Keys.onReturnPressed:{
            confirm();
        }
    }
    Components.EAnimatedWindow {
        id: musicAnimationWindow
        fullscreenColor: theme.secondaryColor
        textColor: theme.textColor

        // 统一入口：从源组件读取音乐信息并打开动画窗口
        function openFrom(sourceItem) {
            if (sourceItem) {
                musicContent.coverImage = sourceItem.coverImage || ""
                musicContent.coverIsDefault = !!sourceItem.coverImageIsDefault
                musicContent.title = sourceItem.songTitle || "未知歌曲"
                musicContent.artist = sourceItem.artistName || "未知艺术家"
            } else {
                musicContent.coverImage = ""
                musicContent.coverIsDefault = false
                musicContent.title = "未知歌曲"
                musicContent.artist = "未知艺术家"
            }
            musicContent.sourceItem = sourceItem || null
            open(sourceItem)
        }

        // 提取后的内容组件（与 Aboutme 用法一致）
        Components.MusicWindow {
            id: musicContent
            anchors.fill: parent
            theme: theme
        }
    }
    
    //顶部
    TopBar {
        id:topbar
        anchors.top:parent.top
        anchors.left:parent.left
        anchors.right:parent.right
        targetwindow: mainWindow
        z:1 //设置层级，让顶部超出的部分可以在leftbar里显示
        property var fullscreen:false
        onFullscreenChanged:{
            if(fullscreen){
                leftbar.anchors.top=topbar.anchors.top;leftbar.left_btn_list.visible=false
            }else{
                topbar.opacity=1
                leftbar.anchors.top=topbar.bottom;leftbar.left_btn_list.visible=true
            }
        }
    }
    //contentitem
    LeftBar {
        id:leftbar
        anchors.top:topbar.bottom
        anchors.left:parent.left
        anchors.right:parent.right
        anchors.bottom:parent.bottom
        ResizeHandle {
            rightEnabled: true
            bottomEnabled:  true
            cornerEnabled:  true
        }
        z:0
    }
    //管理contentitem可拉伸区域
    
    //开启fps检测
    //FpsCounter{id:fpsCounter}
    //onAfterRendering: fpsCounter.update()
    
    //监听窗口变量变化 后续复原
    onWidthChanged:function(width){
        if(mainWindow.state==4)return
        prev_width=width
    }
    onHeightChanged:function(height){
        if(mainWindow.state==4)return
        prev_height=height
    }
    onXChanged:function(x){
        if(mainWindow.state==4)return
        mainWindow.prev_pos.x=x
    }
    onYChanged:function(y){
        if(mainWindow.state==4)return
        mainWindow.prev_pos.y=y
    }
    onVisibilityChanged:function(state){
        //初始显示位置跳过调整
        if(mainWindow.state==-1){mainWindow.state=state;return}
        //最小化后每次显示进行调整
        if(state==2){
            mainWindow.width=prev_width
            mainWindow.height=prev_height
            mainWindow.x=prev_pos.x;mainWindow.y=prev_pos.y
            mainWindow.opacity=0
            opacity_anim.start()
            mainWindow.update()
        }
        mainWindow.state=state
    }
   
    PropertyAnimation{
        id:opacity_anim
        property:"opacity"
        target:mainWindow
        from:0.0
        to:1.0
        duration:200
        easing.type: Easing.OutCubic
    }
}
