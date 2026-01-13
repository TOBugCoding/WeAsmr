import QtQuick
import QtQuick.Controls
import "components" as Components

Item {
    id: content
    property string thisQml
    //跨多个组件就要像这样在顶部声明，再去调用，property就是组件允许跨域访问
    property var child:loader

    property var loader_data
    anchors.fill: parent
    // 主要内容加载器
    Loader {
        asynchronous: true
        id: loader
        anchors.fill: parent
        source: content.thisQml
        onStatusChanged: {
            if (status === Loader.Ready) {
                console.log("QML加载完成:", source)
                move_anim.target = loader.item  // 目标改为加载的内容
                move_anim.start()
            } else if (status === Loader.Error) {
                console.error("QML加载失败:", source)
            }
        }
        PropertyAnimation{
            id:move_anim
            property:"opacity"
            duration:300
            from:  0.0
            to : 1.0
        }
    }
   
    // 加载动画层
    Item {
        id: loadingOverlay
        anchors.fill: parent
        visible: loader.status !== Loader.Ready
        Components.ELoader {
            anchors.centerIn:loadingOverlay
            size: 50
            x: 150
            speed: 0.8
        }
    }
}