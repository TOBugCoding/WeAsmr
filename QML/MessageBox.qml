import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window{
    id: messagebox
    width: 300
    height: 200
    property string text: ""  // 替换var为明确类型string
    property int set_flag:0 //这里设定是否显示ok 取消 按钮,0：只有确认按钮 1：确认+取消
    signal ensure
    signal cancel
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint  // 置顶确保不被遮挡
    color: "#00000000"
    visible: false  // 默认隐藏
    modality: Qt.ApplicationModal  // 关键：应用级模态，阻塞整个应用的交互

    //拖动窗体
    Item{
        anchors.fill:parent 
        MouseArea {
            id: titleBarMouseRegion
            property var clickPos
            anchors.fill: parent
            onPressed: function(mouse){
                clickPos = { x: mouse.x, y: mouse.y }
            }
            onPositionChanged: {
                //mousePosition由main.cpp里注册了单例
                messagebox.x = mousePosition.cursorPos().x - clickPos.x
                messagebox.y = mousePosition.cursorPos().y - clickPos.y
            }
            
        }  
    }
    // 2. 消息框主体（居中显示）
    Column{
        anchors.centerIn: parent  // 改为居中，适配不同屏幕
        property int radius: 10
        width: 300

        // 顶部显示部分
        Rectangle{
            id: topdetail
            color: theme.leftBarColor
            height: 50
            width: parent.width
            topLeftRadius: parent.radius
            topRightRadius: parent.radius

            Text{
                anchors.left:parent.left
                anchors.leftMargin:10
                anchors.verticalCenter:parent.verticalCenter
                text: "ASMR"
                color: theme.fontColor
                font.pixelSize: 14
            }
            HoverButton {
                anchors.right:parent.right
                anchors.rightMargin:10
                anchors.verticalCenter:parent.verticalCenter
                id:closebtn
                image_path:"qrc:/sources/image/close.svg"
                onClicked: messagebox.close()
            }
        }

        Rectangle{height: 2; width: parent.width;color:theme.contentColor}

        // 消息部分
        Rectangle{
            color: theme.leftBarColor
            height: messagebox.height-2-topdetail.height
            width: parent.width
            bottomLeftRadius: parent.radius
            bottomRightRadius: parent.radius
            Row{
                anchors.centerIn:parent
                spacing:10
                Image{
                    Layout.fillWidth: true
                    height:messageContainer.implicitHeight
                    fillMode: Image.PreserveAspectFit
                    source:"qrc:/sources/image/感叹号.svg"
                    verticalAlignment: Image.AlignVCenter
                }
                Text{
                    Layout.fillWidth: true
                    id:messageContainer
                    text: messagebox.text
                    color: theme.fontColor
                    font.pixelSize: 20
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Rectangle{
                visible:messagebox.set_flag>=1
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin:20
                anchors.bottomMargin: 10
                width:close_btn.implicitWidth+20
                height:close_btn.implicitHeight+10
                color:theme.green
                radius:10
                Text{anchors.centerIn:parent;text:"取消";color:"white"}
                MouseArea{
                    anchors.fill:parent
                    hoverEnabled:true
                    cursorShape: Qt.PointingHandCursor
                    onClicked:{messagebox.close_cancel()}
                }
            }
            Rectangle{
                visible:messagebox.set_flag>=0
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: 10
                anchors.rightMargin:20
                width:close_btn.implicitWidth+20
                height:close_btn.implicitHeight+10
                color:theme.green
                radius:10
                Text{id:close_btn;anchors.centerIn:parent;text:"确认";color:"white"}
                MouseArea{
                    anchors.fill:parent
                    hoverEnabled:true
                    cursorShape: Qt.PointingHandCursor
                    onClicked:{messagebox.close_ensure()}
                }
            }
            

        }
    }

    
    function open(){
        messagebox.visible = true;
    }
    function close_cancel(){
        messagebox.visible = false;
        messagebox.cancel();
    }
    function close_ensure(){
        messagebox.visible = false;
        messagebox.ensure();
    }
}