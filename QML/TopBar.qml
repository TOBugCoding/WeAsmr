import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import com.asmr.player 1.0
import QtQuick.Shapes
import "components" as Components
Item {
    id: root
    focus: true
    property var child:searchInput //搜索框
    property var targetwindow:null
    property int minimizeDuration: 300
    height: layout.implicitHeight+5  // 保持固定高度
    width: parent.width  // 宽度跟随父元素
    property int topbar_height:80
    property bool isDragging: false
    property point dragStart
    property bool isMaximized: false
    property var history:[]
    property int now_pos:0
    property bool can_minize:false//记录是否消除了小型窗口
    property bool search_focus:false//记录搜索框焦点
    //浏览记录按钮是否可点击
    function history_show(){
        if(now_pos==0){
            left_history.btn_clear()
        }else{
            left_history.btn_restor()
        }

        if(now_pos==history.length-1){
            right_history.btn_clear()
        }else{
            right_history.btn_restor()
        }
    }
    onNow_posChanged:{
       history_show()
    }
    PropertyAnimation{
        id:topbar_hide
        property:"opacity"
        target:root
        to:0.0
        duration:200
        easing.type: Easing.OutCubic
    }
    PropertyAnimation{
        id:topbar_show
        property:"opacity"
        target:root
        to:1.0
        duration:200
        easing.type: Easing.OutCubic
    }
    // 原有的RowLayout作为内部布局
    Item{
        z:3
        id:base_item
        anchors.fill: parent
        Rectangle{
            anchors.fill:parent
            color:"#00000000"
            MouseArea {
                id: titleBarMouseRegion
                property var clickPos
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: function(mouse){
                    if(pressed){
                        clickPos = { x: mouse.x, y: mouse.y }
                        //抢夺焦点
                        titleBarMouseRegion.forceActiveFocus()
                    }

                }
                onPositionChanged: {
                    //mousePosition由main.cpp里注册了单例
                    root.targetwindow.x = mousePosition.cursorPos().x - clickPos.x
                    root.targetwindow.y = mousePosition.cursorPos().y - clickPos.y
                }
                onDoubleClicked: {
                    maxmize_btn.clicked();
                }

            }
        }
        RowLayout {
            id:layout
            anchors.fill: parent  // 充满整个根Item
            spacing: 0

            //左侧间距 定义最大高度
            Item{
                height:root.topbar_height
                Layout.preferredWidth: leftbar.btnWidth * 1.5  // 首选宽度（匹配左侧菜单）
                Layout.fillHeight: true                       // 高度充满RowLayout（即顶部栏高度）
                Rectangle{
                    anchors.fill:parent
                    color: theme.leftBarColor
                    opacity: theme.opacity
                }
                Row{
                    anchors.centerIn:parent
                    //Image{width:40;height:40;source:"qrc:/sources/image/QQ音乐.svg"}//这里后续可以加自己的log
                    Label {
                        //font.family:iconFont.name
                        font.pointSize:15
                        color:theme.fontColor
                        id: titleLabel
                        text: qsTr("🌙 ASMR")
                        //topPadding:6
                    }
                }
            }
            Item{
                Layout.fillWidth: true
                Layout.fillHeight:true
                Rectangle{
                    anchors.fill:parent
                    color: theme.contentColor //Theme在main.cpp里声明了id
                    opacity:theme.opacity
                }
                RowLayout{
                    spacing:15
                    anchors.verticalCenter:parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 15  // 左侧整体间距（替代原来的Item）
                    anchors.right: parent.right
                    anchors.rightMargin: 15 // 右侧整体间距
                    //左历史回滚
                    HoverButton{
                        id:left_history
                        image_path:"qrc:/sources/image/y_icon_line_direction_arrow_right.svg"
                        Component.onCompleted: {
                            m_rotation = 180
                        }
                        onClicked: {
                           if(root.now_pos!=0){
                                root.now_pos--;
                                leftbar.thisQml=root.history[root.now_pos]
                            }
                        }

                    }
                    //右历史回滚
                    HoverButton{
                        id:right_history
                        image_path:"qrc:/sources/image/y_icon_line_direction_arrow_right.svg"
                        onClicked: {
                           if(root.now_pos!=root.history.length-1){
                                root.now_pos++;
                                leftbar.thisQml=root.history[root.now_pos]
                            }
                        }
                    }

                    //搜索框输入
                    TextField {
                        id: searchInput
                        placeholderText: "输入关键词"
                        placeholderTextColor:Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.5);//降低50的透明度
                        text:""
                        color:theme.fontColor
                        Layout.preferredWidth: root.width * 0.15
                        Keys.onReturnPressed: searchButton.clicked()
                        Keys.onEnterPressed: searchButton.clicked()
                        background: Rectangle {color: theme.leftBarColor;radius: 20}
                        selectByMouse: false
                    }
                    HoverButton{
                        id: searchButton
                        image_path:"qrc:/sources/image/y_icon_line_edit_search.svg"
                        onClicked: {
                                leftbar.thisQml="qrc:/QML/content/SearchShowPage.qml"
                                //搜索页数默认为1
                                ASMRPlayer.set_page(1)
                                leftbar.current_list_view=""
                                ASMRPlayer.search_list(searchInput.text)
                        }
                    }
                    Item {
                        Layout.fillWidth: true //自动填充剩余区域
                    }

                    //颜色
                    HoverButton{
                        image_path:theme.isDark?"qrc:/sources/image/太阳.svg":"qrc:/sources/image/月亮-fill.svg"
                        onClicked:{theme.isDark=!theme.isDark}
                    }
                    //透明度
                    HoverButton{
                        id:skin_btn
                        image_path:"qrc:/sources/image/皮肤.svg"
                        onClicked:{console.log("弹出滑动条，调整透明度");opacity_mng.visible=true}
                        Rectangle{
                            id:opacity_mng
                            anchors.top:parent.bottom
                            anchors.horizontalCenter:parent.horizontalCenter
                            width: 32  // 垂直 Slider 需设置宽度（窄）
                            height: 120 // 垂直 Slider 需设置高度（高）
                            visible:false
                            color:theme.leftBarColor
                            radius:20
                            Slider{
                                id:opacity_body
                                width:parent.width/2
                                height:parent.height
                                anchors.centerIn:parent
                                wheelEnabled:true
                                value:0.8
                                from:1
                                to:0.2
                                stepSize:0.1
                                orientation:Qt.Vertical
                                onValueChanged:{
                                    theme.opacity=value
                                }
                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        opacity_mng.visible=false
                                    }
                                }
                                background:Rectangle{
                                    height:opacity_body.availableHeight
                                    width:opacity_body.availableWidth
                                    radius:10
                                    color:theme.green
                                    anchors.horizontalCenter:parent.horizontalCenter
                                    gradient: Gradient {
                                        GradientStop { position: 1.0; color: theme.green }          // 起始颜色
                                        GradientStop { position: 0.0; color: theme.green + "80" }   // 结束颜色（80=128，半透明）
                                    }

                                }
                                handle: Rectangle {
                                    anchors.horizontalCenter:parent.horizontalCenter
                                    y: opacity_body.visualPosition * (opacity_body.availableHeight - height)
                                    x: opacity_body.availableWidth / 2 - width / 2
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: 13
                                    color: opacity_body.pressed ? "#f0f0f0" : "#f6f6f6"
                                    border.color: "#bdbebf"
                                }


                            }

                            onVisibleChanged:{
                                if(visible){
                                    opacity_body.forceActiveFocus()
                                }
                            }
                        }
                    }
                    HoverButton{
                        image_path:"qrc:/sources/image/竖线.svg"
                        can_hover:false
                        height:25
                    }
                    HoverButton{
                        id:mini_btn
                        image_path:"qrc:/sources/image/icon_minimize.svg"
                        onEntered:{if(!root.can_minize){pre_minitxt.forceActiveFocus();}}
                        onClicked:{root.targetwindow.showMinimized();}
                        TextInput{
                            opacity:0
                            id:pre_minitxt
                            Component.onCompleted: {
                                pre_minitxt.forceActiveFocus()
                            }
                        }
                        TextInput{
                            opacity:0
                            id:mini_text
                            anchors.fill:parent
                            text:"测试"
                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    root.targetwindow.showMinimized();
                                    root.can_minize=true
                                    //console.log("第一次点击")
                                    focus=false
                                    mini_text.visible=false
                                }
                            }
                        }
                    }
                    HoverButton {
                        id:maxmize_btn
                        image_path: "qrc:/sources/image/icon_maxmize.svg"
                        onClicked: function(){
                            if (root.targetwindow.visibility===Window.FullScreen) {
                                root.targetwindow.showNormal();
                            } else {
                                root.targetwindow.showFullScreen();
                            }
                            root.isMaximized = !root.isMaximized;
                        }
                    }
                    HoverButton {
                        id:closebtn
                        image_path:"qrc:/sources/image/close.svg"
                        onClicked: exitDialog.open()
                    }

                }
            }
        }
    }
    Item{
        z:1
        anchors.top:parent.top
        anchors.left:parent.left
        anchors.right:parent.right
        height:titleBarMouseRegion.height+5
        MouseArea{
               id: topbarHoverArea // 增加id，方便获取区域坐标
               anchors.fill:parent
               hoverEnabled:true
               // 鼠标进入：全屏时显示顶部栏（原有逻辑保留）
               onEntered:{if(topbar.fullscreen)topbar_show.start()}
               // 鼠标离开：增加真实位置判断，仅真正移出时隐藏
               onExited: {
                   if(topbar.fullscreen) {
                       // 获取当前鼠标全局坐标
                       var mouseGlobalPos = mousePosition.cursorPos();
                       // 将全局坐标转换为当前MouseArea的本地坐标
                       var mouseLocalPos = topbarHoverArea.mapFromGlobal(mouseGlobalPos.x, mouseGlobalPos.y);
                       // 判定
                       var isMouseInArea = (mouseLocalPos.x >= 0 && mouseLocalPos.x < topbarHoverArea.width)
                                        && (mouseLocalPos.y >= 0 && mouseLocalPos.y < topbarHoverArea.height);
                       // 仅当鼠标真正移出区域时，才设置opacity为0
                       if(!isMouseInArea) {
                           topbar_hide.start();
                       }
                   }
               }
        }
    }

    Shortcut{
        sequence: "esc"
        onActivated: {
            closebtn.clicked()
            console.log("触发")
        }

    }
    
    Component.onCompleted: {
        root.history.push(leftbar.thisQml)
        history_show()
    }
}
