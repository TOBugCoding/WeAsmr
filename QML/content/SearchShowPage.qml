import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import com.asmr.player 1.0
import QtQuick.Dialogs
import "../control"
import "../"
import "../components"
import "../components/MediaUtils.js" as MediaUtils
Item {
    opacity:0
    id: searchtPage
    property int page:1//当前页数
    property int totalpage:1//总页数
    property string currentPlaying: ""
    // 连接加载完成信号
    Connections {
        target: ASMRPlayer
        function onAsmrSearchReceived(audioList) {
            // 清空旧数据
            audioListModel.clear();
            // 将C++的QList<QString>转换为QML的列表并填充模型
            for (let i = 0; i < audioList.length; i++) {
                audioListModel.append({
                    audioPath: audioList[i].name,
                    is_dir:audioList[i].isDir
                });
            }
            console.log("搜索结果加载完成，共" + audioList.length + "条");
        }
        function onPageChanged(_page){
            //无论是重复搜索还是不是，都重新加载
            searchtPage.page=_page
            audioListModel.clear();
        }
        function onCurrent_playing_changed(){
            searchtPage.currentPlaying=ASMRPlayer.get_current_playing();
        }
        function onTotalPageChanged(_page){
            console.log("总页数"+_page)
            searchtPage.totalpage=_page
        }

    }
    SelectCollect{
        id:selectCollect
    }
    RowLayout {
        id: title_head
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        Layout.rightMargin: 20
        anchors.leftMargin: 50
        //右侧 显示页面 上一页 下一页
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 10

            HoverButton{
                image_path:"qrc:/sources/image/箭头_上一页.svg"//箭头_下一页.svg
                onClicked: {
                    if(searchtPage.page<=1){return;}
                    let _page=ASMRPlayer.get_page()-1;
                    ASMRPlayer.set_page(_page);
                    ASMRPlayer.search_list(ASMRPlayer.get_search_path())
                }
            }
            Text{
                text:"当前页数: "+searchtPage.page+" / "+searchtPage.totalpage
                font.pointSize:9
                color:theme.fontColor
            }
            HoverButton{
                image_path:"qrc:/sources/image/箭头_下一页.svg"//箭头_下一页.svg
                onClicked: {
                    if(searchtPage.page>=searchtPage.totalpage){return;}//当当前页数大于等于总页数就不能下一页
                    console.log("下一页")
                    let _page=ASMRPlayer.get_page()+1;
                    ASMRPlayer.set_page(_page);
                    ASMRPlayer.search_list(ASMRPlayer.get_search_path())
                }
            }
            Item{width:5}

        }
    }
    Item {
        anchors.top: title_head.bottom
        anchors.left: parent.left
        anchors.leftMargin:50
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        ListView {
            id: asmrshow_list
            width: parent.width
            height: parent.height-50
            acceptedButtons:Qt.NoButton
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
            delegate: AudioListItem {
                id: listItem
                itemName: model.audioPath
                downloadUrl: model.audioPath
                cancelUrl: model.audioPath
                currentPlaying: "/" + searchtPage.currentPlaying
                playingComparePath: model.audioPath

                handleClick: function(mouse) {
                    let audioPath = model.audioPath
                    if (model.is_dir) {
                        ASMRPlayer.set_page(1)
                        ASMRPlayer.set_path(audioPath.substring(1) + "/")
                        ASMRPlayer.pushHistory(audioPath.substring(1) + "/", 1, 1)
                        leftbar.force_fresh = 1
                        leftbar.thisQml = "qrc:/QML/content/Asmr_list.qml"
                        leftbar.current_list_view = "ASMR"
                        return
                    }
                    var isMedia = MediaUtils.isMediaFile(audioPath)
                    if (!isMedia) {
                        ASMRPlayer.get_sign_path(audioPath)
                        return
                    }
                    if (currentPlaying !== model.audioPath) {
                        currentPlaying = model.audioPath.substring(1)
                        ASMRPlayer.set_current_playing(currentPlaying)
                        ASMRPlayer.get_sign_path(model.audioPath)
                        let targetLrc = model.audioPath.split(".").slice(0, -1).join(".") + ".lrc"
                        if (targetLrc === model.name) return
                        for (var i = 0; i < audioListModel.count; i++) {
                            var item = audioListModel.get(i)
                            if (item.audioPath === targetLrc) {
                                ASMRPlayer.download_vlc_path(item.audioPath)
                                return
                            }
                        }
                        ASMRPlayer.show_vlc(false)
                    }
                }

                HoverButton {
                    visible: !model.is_dir
                    image_path: "qrc:/sources/image/我喜欢的.svg"
                    onClicked: selectCollect.open(model.audioPath.substring(1))
                    width: 24; height: 24
                }
                HoverButton {
                    visible: !model.is_dir
                    image_path: "qrc:/sources/image/下载.svg"
                    onClicked: ASMRPlayer.download_sign_path(model.audioPath, model.audioPath)
                    width: 24; height: 24
                }
                HoverButton {
                    visible: model.is_dir
                    image_path: "qrc:/sources/image/文件夹.svg"
                    can_hover: false
                    width: 24; height: 24
                }
            }
        }
        Item {
            id: loadingOverlay
            anchors.fill: parent
            visible: false
            ELoader {
                anchors.centerIn: parent
                size: 50
                speed: 0.8
            }
        }
    }

    Component.onCompleted: {
        currentPlaying=ASMRPlayer.get_current_playing()
        loadingOverlay.visible = (audioListModel.count === 0);
    }
}
