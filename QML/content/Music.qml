import QtQuick
import QtQuick.Layouts
import QtQuick.Controls     // 新增
import "../"

Flickable {
    id: flick
    anchors.fill: parent
    contentHeight: flow.implicitHeight // 50px padding at bottom
    contentWidth: flow.implicitWidth
    opacity:0 //初始透明度为0 动画加载过渡
    boundsBehavior: Flickable.StopAtBounds
    clip: true  //超出范围就裁剪

    Flow {
        id: flow
        MusicComponents {}
        onImplicitHeightChanged: {
            console.log("Flow 高度已更新:", implicitHeight);
        }
        
    }
    ScrollBar.vertical: ScrollBar { }   
}