import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QuickVLC

import "components" as Components
ApplicationWindow {
    id:mainWindow
    visible: true
    width: now_width;height: now_height
    minimumWidth:720;minimumHeight:480
    //flags:Qt.Window|Qt.FramelessWindowHint|Qt.WindowStaysOnTopHint
    flags:Qt.Window|Qt.FramelessWindowHint
    //管理大小位置的重现
    property int now_width:1080
    property int now_height:600
    property var prev_pos:Qt.vector2d(0,0)
    property int prev_width:now_width
    property int prev_height:now_height
    property int state:-1
    title: ""
    color:"#00000000" //比设置background更高效，并且最好不用transparent，否则要加上Qt.WA_TranslucentBackground
    //background:Rectangle{color:"#00000000"}

    //页面缓存管理
    FontLoader {
        id: iconFont
        source: "qrc:/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
    }
    Components.ETheme {
        id: theme
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


    //顶部
    TopBar {
        id:topbar
        anchors.top:parent.top
        anchors.left:parent.left
        anchors.right:parent.right
        targetwindow: mainWindow
        z:1 //设置层级，让顶部超出的部分可以在leftbar里显示
        property bool fullscreen:false
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
        if(mainWindow.state===-1){
            mainWindow.state=state;
            return;
        }
        //最小化后每次显示进行调整
        if(state===2){
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
