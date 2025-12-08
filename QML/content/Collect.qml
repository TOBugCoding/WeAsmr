import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import com.asmr.player 1.0
import QtQuick.Dialogs
import "../control"
import "../"
import "../components"
Item {
    opacity:0
    id: collectPage
    property string currentPlaying: ""
    property string currentCollectFile:ASMRPlayer.get_collect_file()
    // 连接加载完成信号
    Connections {
        target: ASMRPlayer
        function onCollectCompelet(audioList) {
            // 清空旧数据
            audioListModel.clear();
            // 将C++的QList<QString>转换为QML的列表并填充模型
            for (let i = 0; i < audioList.length; i++) {
                audioListModel.append({
                    audioPath: audioList[i],
                    // 可选：提取音频名称（截取最后一个/后的部分）
                    name: audioList[i].split("/").pop()
                });
            }
            console.log("收藏夹加载完成，共" + audioList.length + "首音频");
        }
        function onCollect_file_changed(){collectPage.currentCollectFile=ASMRPlayer.get_collect_file()}
    }
    
    MessageBox {
        id: collectDetail
        set_flag:0+1
        onEnsure:{
            ASMRPlayer.delete_collection(collectPage.currentCollectFile)
            ASMRPlayer.set_collect_file("默认收藏夹")        
        }
    }
    // 显示音频列表的ListView
     //列表实体显示区域
    Item{
        id:titlehead
        height:100
        anchors.left: parent.left
        anchors.leftMargin:50
        anchors.right: parent.right
        Item{
            anchors.fill:parent
            Text{id:collect_title;text:collectPage.currentCollectFile;color:theme.fontColor;font.pointSize:25}
   
            HoverButton{
                anchors.top:collect_title.bottom
                anchors.topMargin:20
                image_path:"qrc:/sources/image/垃圾桶.svg";
                onClicked:{
                    collectDetail.text="确认要删除吗"
                    if(collectPage.currentCollectFile=="默认收藏夹"){
                        collectDetail.text="默认收藏夹不能删除"
                    }
                    collectDetail.open()
                }
            }
            
          
        }
    }
    Item {
        anchors.top: titlehead.bottom
        anchors.left: parent.left
        anchors.leftMargin:50
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        ListView {
            id: asmrshow_list
            width: parent.width
            height: parent.height
            //clip: true // 开启裁剪，避免放大内容超出列表
            ScrollBar.vertical:ScrollBar{
                anchors.right: parent.right
                width:13
            }
            model: ListModel { 
                id: audioListModel
                onCountChanged: {
                    loadingOverlay.visible = (count === 0);
                }
            }
            delegate: Item {
                id: listItem // 列表项根容器（尺寸固定，不参与缩放）
                width: asmrshow_list.width-30
                height: 50 // 固定高度，不随缩放变化
                // 核心：内部可缩放容器（视觉放大，不影响布局）
                Item {
                    id: scaleContainer
                    anchors.fill: parent
                    transformOrigin: Item.Center
                    scale: 1.0 // 默认缩放比例
                    
                    // 背景容器（当前播放项高亮）
                    Item {
                        anchors.fill: parent
                        // 鼠标区域覆盖整个缩放容器
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const name = String(model.name); 
                                if(name.indexOf(".") === -1){
                                    return;
                                }
                                //检测到音频开始播放
                                let playUrl = "https://mooncdn.asmrmoon.com" + "/" + model.audioPath + 
                                                "?sign=J6Pg2iI3DmhltIzETpxWUM13oVCCHYw6jHEtlrFKWOE=:0";
                                console.log(playUrl)
                                if(currentPlaying != model.name){
                                    leftbar.child.exposedMediaPlayer.stop()
                                    leftbar.child.exposedMediaPlayer.source = playUrl
                                    leftbar.child.exposedMediaPlayer.play()
                                }
                                currentPlaying = model.name
                            }
                            // 悬停进入：启动放大动画
                            onEntered: {
                                if (scaleRestoreAnim.running) scaleRestoreAnim.stop()
                                if (!scaleGrowAnim.running) scaleGrowAnim.start()
                                bgRect.color=theme.fontColor
                            }
                        
                            // 悬停离开：启动恢复动画
                            onExited: {
                                if (scaleGrowAnim.running) scaleGrowAnim.stop()
                                if (!scaleRestoreAnim.running) scaleRestoreAnim.start()
                                bgRect.color="#00000000"
                            }
                        
                            // 放大动画（缩放比例从1→1.02）
                            PropertyAnimation {
                                id: scaleGrowAnim
                                target: scaleContainer
                                property: "scale"
                                from: 1.0
                                to: 1.02 // 放大1.05倍（建议1.0~1.1，避免过度放大）
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                        
                            // 恢复动画（缩放比例回到1）
                            PropertyAnimation {
                                id: scaleRestoreAnim
                                target: scaleContainer
                                property: "scale"
                                from: scaleContainer.scale
                                to: 1.0
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                            Rectangle{
                                anchors.fill: parent
                                color: "#00000000"
                                opacity:0.2
                                radius: 4
                                id: bgRect
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: 15
                                //添加到收藏列表
                              
                                Text {
                                    text: model.audioPath
                                    font.pixelSize: 16
                                    color: currentPlaying == model.name ? theme.green : theme.fontColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.leftMargin: 0
                                }
                            }
                        }
                      
                    }

                    
                }
            }
        }
        Item {
            id: loadingOverlay
            anchors.fill: parent
            visible: false
            Text{
                anchors.centerIn:parent
                text:"没找到音频"
                font.pointSize:30
                color:theme.fontColor
            }
        }
    }

    Component.onCompleted: {
        ASMRPlayer.load_audio(ASMRPlayer.get_collect_file());
        loadingOverlay.visible = (audioListModel.count === 0);
    }
}
