import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import com.asmr.player 1.0 // 引入ASMRPlayer，调用get_all_collections

// 收藏夹选择对话框
Window {
    id: selectDialog
    width: 130
    height: folderListView.contentHeight>200?200+20:folderListView.contentHeight+20 //固定高度
  
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    // 对外暴露的属性
    property string selectedFolder: "" // 选中的收藏夹名称（返回值）
    property string defaultSelected: "" // 默认选中的收藏夹名称
    property string msg;
    color:"#00000000"
    function loadModel(){
        let folderList = ASMRPlayer.get_all_collections();
        folderList.reverse();
        // 2. 填充列表模型
        folderModel.clear();
        folderList.forEach(folderName => {
            folderModel.append({ name: folderName });
        });
    }
    Timer {
        id: close_timer
        interval: 1000
        onTriggered: selectDialog.close()
    }
    // 收藏夹列表模型
    ListModel {
        id: folderModel
    }
    Rectangle{
        anchors.fill:parent
        color:theme.leftBarColor
        radius:10
        MouseArea{
            anchors.fill:parent
            hoverEnabled:true
            onEntered:{close_timer.stop()}
            onExited:{close_timer.restart()}
            ListView {
                id: folderListView
                anchors.fill:parent
                anchors.margins:10
                boundsBehavior: Flickable.StopAtBounds
                spacing:5
                ScrollBar.vertical:ScrollBar{
                    anchors.right: parent.right
                    width:13
                }
                model: folderModel
                clip: true
                delegate: Item {
                    width: 100
                    height: 20
                    // 选中状态背景
                    Rectangle {
                        anchors.fill: parent
                        color: folderListView.currentIndex === index ? theme.globalColor : "transparent"
                        opacity: folderListView.currentIndex === index ? 0.8 : 0
                        radius: 4
                    }

                    Text {
                        anchors.centerIn: parent
                        text: model.name
                        font.pointSize: 14
                        color: theme.fontColor
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled:true
                        onEntered:{
                            folderListView.currentIndex = index;
                            selectDialog.selectedFolder = model.name;
                        }
                        onClicked: {
                            // 点击列表项选中
                            selectDialog.close();
                            leftbar.collect_add_message=selectDialog.selectedFolder
                            ASMRPlayer.collect_audio(selectDialog.selectedFolder,selectDialog.msg);
                        }
                    }
                }
            }
        }
        
    }
   
    function close(){
        selectDialog.visible=false
    }
    //打开时传入要保存的信息
    function open(_msg){
        //加载收藏夹
        loadModel()
        selectDialog.visible=false
        selectDialog.msg=_msg
    
        //初始化位置
        let mousepos = mousePosition.cursorPos()
        let dialogH = selectDialog.height // 弹窗自身高度
        selectDialog.x = mousepos.x + 30
        selectDialog.y = mousepos.y - dialogH/2
        //显示
        selectDialog.visible=true;
 
    }
    
    
}