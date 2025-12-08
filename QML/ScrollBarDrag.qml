import QtQuick
import QtQuick.Controls.Basic
Rectangle {
    id: scrollBar
    property var target
    property var control_target
    width: target ? target.width : 0
    height: target ? target.height : 0
    //anchors.right: target.right
    color: "red"
    default property alias contentData: contentArea.data
    function init(){console.log(scrollBar.width+" "+scrollBar.height)}
    Component.onCompleted: init()
    
    Timer {
        id: hideTimer
        interval: 100  // 100毫秒延迟，可根据需要调整
        repeat:false
        onTriggered: {
            var lastPos=scrollBar.mapFromGlobal(mousePosition.cursorPos())
            console.log("定时器触发，检查鼠标位置:", lastPos)
            // 再次检查鼠标是否真的离开了区域
            if (!(lastPos.x >= 0 && lastPos.x <= scrollBar.width && 
                    lastPos.y >= 0 && lastPos.y <= scrollBar.height)) {
                scrollBar.control_target.opacity = 0
                console.log("鼠标已离开区域，隐藏滚动条")
            }else{console.log("鼠标未离开")}
        }
    }
    MouseArea {
        id: mouseArea
        width: parent.width
        height: parent.height
        hoverEnabled: true
        property point lastPos: Qt.point(0, 0)

        onPositionChanged: function(mouse){
            lastPos = Qt.point(mouse.x, mouse.y)
        }

        onEntered: {
            //console.log(scrollBar.z+" "+scrollBar.control_target.z+" "+scrollBar.target.z)
             console.log("enter")
            scrollBar.control_target.opacity = 1
            //hideTimer.stop()
        }

        onExited: {
            console.log("exite")
            // 这里设置10为检测误差，取决于mouse刷新的帧率
            if (!(lastPos.x >= 0 && lastPos.x <= scrollBar.width && 
                    lastPos.y >= 0 && lastPos.y <= scrollBar.height)) {
                scrollBar.control_target.opacity = 0
                //再设定一个定时器,防止快速移动时opacity无法归0
            }
        }
        Item {
            id: contentArea
            anchors.fill: parent
            // 外部的内容会自动加到这里
        }
    }
}
