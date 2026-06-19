import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QuickVLC
import QtQuick.Layouts
import QtQuick.Controls.Basic
import com.asmr.player 1.0
import "../control"
import "../"
import "../components"
import "../components/MediaUtils.js" as MediaUtils
Item {
    id: asmr_list_body
    opacity: 0
    property string currentPlaying: ""
    property string file: ""
    property int page:1//当前页数
    property int totalpage:1//总页数
    property var pathParts

    onFileChanged: {
        pathParts = Qt.binding(function() {
            if (!file) return ["主页"];
            var parts = file.split('/').filter(part => part !== "");
            parts.unshift("主页");
            return parts;
        });

    }
    //检测节目列表变化，并实时更新
    Connections {
        target: ASMRPlayer
        function onAsmrNamesReceived(nameList) {
            listModel.clear();
            for (let i = 0; i < nameList.length; i++) {
                listModel.append({ name: nameList[i].name,is_dir: nameList[i].isDir});
            }
            asmrshow_list.contentY=0
        }
        function onPageChanged(_page){
            asmr_list_body.page=_page
            listModel.clear();
        }
        function onTotalPageChanged(_page){
            asmr_list_body.totalpage=_page
            ASMRPlayer.fixTotalHistory(totalpage)
        }
        function onCurrent_playing_changed(){
            asmr_list_body.currentPlaying=ASMRPlayer.get_current_playing();
        }
        function onSigFilePath(filepath){
            file=filepath.file
            ASMRPlayer.set_page(filepath.now_page);
            totalpage=filepath.total_page
            ASMRPlayer.asmr_list(file,false);
        }
    }
    SelectCollect{
        id:selectCollect
    }
    //文件夹路径
    RowLayout {
        id: title_head
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        Layout.rightMargin: 20  
        anchors.leftMargin: 50
        //行布局
        Flow {
            id: pathNavigation
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            spacing: 2
            //重复组件
            Repeater {
                model: pathParts?.length ?? 0
                delegate: row_title
            }
        }
        //右侧 显示页面 上一页 下一页
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 10  
         
            HoverButton{
                image_path:"qrc:/sources/image/箭头_上一页.svg"//箭头_下一页.svg
                onClicked: {
                    if(asmr_list_body.page<=1){return;}
                    let _page=ASMRPlayer.get_page()-1;
                    ASMRPlayer.set_page(_page);
                    ASMRPlayer.fixHistory(_page);
                    ASMRPlayer.asmr_list(ASMRPlayer.get_path(), false)
                }
            }
            Text{
                text:"当前页数: "+asmr_list_body.page+" / "+asmr_list_body.totalpage
                font.pointSize:9
                color:theme.fontColor
            }
            HoverButton{
                image_path:"qrc:/sources/image/箭头_下一页.svg"//箭头_下一页.svg
                onClicked: {
                    if(asmr_list_body.page>=asmr_list_body.totalpage){return;}//当当前页数大于等于总页数就不能下一页
                    console.log("下一页")
                    let _page=ASMRPlayer.get_page()+1;
                    ASMRPlayer.set_page(_page);
                    ASMRPlayer.fixHistory(_page);
                    ASMRPlayer.asmr_list(ASMRPlayer.get_path(), false)
                }
            }
            Item{width:5}
            
        }
    }
    //文件夹路径repeater组件
    Component{
        id:row_title
        Row {
            spacing: 2
            Text {
                id: folderText
                color: theme.fontColor
                text: pathParts[index]
                font.pointSize: 15
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered:{folderText.color=theme.green}
                    onExited:{folderText.color=Qt.binding(function() { return theme.fontColor })}
                    onClicked: {
                        //回退目录时清空当前ui显示
                        if(index===pathParts.length-1){
                            return;
                        }
                        listModel.clear();
                        var newPath = "";
                        for (var i = 0; i <= index; i++) {
                            if (i === 0 && pathParts[i] === "主页") {
                                newPath = "";
                            } else if (i === 1) {
                                newPath += pathParts[i];
                            } else if (i > 1) {
                                newPath += "/" + pathParts[i];
                            }
                        }
                        ASMRPlayer.set_page(1);
                        if (index === 0) {
                            file = "";
                            ASMRPlayer.asmr_list("", false);//这里false显示说明不要加/后缀
                            ASMRPlayer.pushHistory("/",1,1);
                        } else {
                            file = newPath;
                            ASMRPlayer.asmr_list(newPath,true);
                            ASMRPlayer.pushHistory(newPath+"/",1,1);

                        }                  
                    }
                }
            }
                    
            Text {
                color: theme.fontColor
                text: index < pathParts.length - 1 ? "/" : ""
                font.pointSize: 15
                visible: index < pathParts.length - 1
            }
        }
    }
    //列表实体显示区域
    Item {
        anchors.top: title_head.bottom
        anchors.topMargin: 40
        anchors.left: parent.left
        anchors.leftMargin:50
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        ListView {
            id: asmrshow_list
            width: parent.width
            height: parent.height-50
            //clip: true // 开启裁剪，避免放大内容超出列表
            acceptedButtons:Qt.NoButton
            ScrollBar.vertical:ScrollBar{
                anchors.right: parent.right
                width:13
            }
            model: ListModel { 
                id: listModel 
                onCountChanged: {
                    loadingOverlay.visible = (count === 0);
                }
            }
            delegate: AudioListItem {
                id: listItem
                itemName: model.name
                downloadUrl: "/" + ASMRPlayer.get_path() + model.name
                cancelUrl: "/" + ASMRPlayer.get_path() + model.name
                currentPlaying: asmr_list_body.currentPlaying
                playingComparePath: ASMRPlayer.get_path() + model.name

                handleClick: function(mouse) {
                    if (model.is_dir) {
                        file = ASMRPlayer.get_path() + model.name + "/"
                        let next_path = ASMRPlayer.get_path() + model.name
                        ASMRPlayer.set_page(1)
                        ASMRPlayer.asmr_list(next_path, true)
                        if (file) {
                            ASMRPlayer.pushHistory(file, page, totalpage)
                        } else {
                            ASMRPlayer.pushHistory("", page, totalpage)
                        }
                        return
                    }
                    var isMedia = MediaUtils.isMediaFile(model.name)
                    let purepath = ASMRPlayer.get_path() + model.name
                    let isSameFile = (currentPlaying === purepath)
                    if (!isMedia) {
                        ASMRPlayer.get_sign_path("/" + purepath)
                        return
                    }
                    currentPlaying = purepath
                    ASMRPlayer.set_current_playing(currentPlaying)
                    if (!isSameFile) {
                        ASMRPlayer.get_sign_path("/" + purepath)
                        let targetLrc = model.name.split(".").slice(0, -1).join(".") + ".lrc"
                        if (targetLrc === model.name) return
                        for (var i = 0; i < listModel.count; i++) {
                            var item = listModel.get(i)
                            if (item.name === targetLrc) {
                                ASMRPlayer.download_vlc_path(ASMRPlayer.get_path() + item.name)
                                return
                            }
                        }
                        ASMRPlayer.show_vlc(false)
                    }
                }

                HoverButton {
                    visible: !model.is_dir
                    image_path: "qrc:/sources/image/我喜欢的.svg"
                    onClicked: selectCollect.open(ASMRPlayer.get_path() + model.name)
                    width: 24; height: 24
                }
                HoverButton {
                    visible: !model.is_dir
                    image_path: "qrc:/sources/image/下载.svg"
                    onClicked: ASMRPlayer.download_sign_path("/" + ASMRPlayer.get_path() + model.name, "/" + ASMRPlayer.get_path() + model.name)
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

        Text {
            id: noResultText
            anchors.centerIn: parent
            text: "暂无结果"
            font.pointSize: 20
            color: theme.fontColor
            visible: false
            Behavior on opacity { NumberAnimation { duration: 300 } }
            opacity: visible ? 1 : 0
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
        console.log("加载页面asmrlist成功")
        listModel.clear();
         //预先加载之前数据
        if(leftbar.force_fresh===0)
        {
            console.log("复用列表")
            let nameList=ASMRPlayer.get_nameList()
            for (let i = 0; i < nameList.length; i++) {
                listModel.append({ name: nameList[i].name,is_dir: nameList[i].isDir});
            }
            asmrshow_list.contentY=0
            //asmr_list_body.totalpage=ASMRPlayer.get_totalpage()
            //asmr_list_body.page=ASMRPlayer.get_page()
            ASMRPlayer.curentHistory()
        }
        file = ASMRPlayer.get_path()
        currentPlaying=ASMRPlayer.get_current_playing()
        //没有数据进行网络接口请求
        if(listModel.count===0){
            ASMRPlayer.asmr_list(file, false)
            leftbar.force_fresh=0
        }
        loadingOverlay.visible = (listModel.count === 0);
    }
}
