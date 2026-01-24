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
        }
        function onCurrent_playing_changed(){
            asmr_list_body.currentPlaying=ASMRPlayer.get_current_playing();
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
        RowLayout {
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
                    ASMRPlayer.set_page(ASMRPlayer.get_page()-1);
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
                    ASMRPlayer.set_page(ASMRPlayer.get_page()+1);
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
                        } else {
                            file = newPath;
                            ASMRPlayer.asmr_list(newPath,true);
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
            height: parent.height
            //clip: true // 开启裁剪，避免放大内容超出列表
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
            delegate: Item {
                id: listItem // 列表项根容器（尺寸固定，不参与缩放）
                width: asmrshow_list.width-30
                height: 50 // 固定高度，不随缩放变化
                // 核心：内部可缩放容器（视觉放大，不影响布局）
                property real downloadProgress: dowloadmgr.getDownloadProgress("/" + ASMRPlayer.get_path()+model.name)
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
                                if(model.is_dir){
                                    file = ASMRPlayer.get_path() + model.name + "/";
                                    let next_path=ASMRPlayer.get_path() + model.name;
                                    ASMRPlayer.set_page(1);//set_page会自动刷新
                                    ASMRPlayer.asmr_list(next_path, true);
                                    return;
                                }
                                //检测到音频开始播放

                                if(currentPlaying !== model.name){
                                    ASMRPlayer.get_sign_path("/" + ASMRPlayer.get_path()+model.name);
                                }
                                currentPlaying = ASMRPlayer.get_path()+model.name
                                ASMRPlayer.set_current_playing(currentPlaying)
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
                            Rectangle{
                                id:dowloadShow
                                property real dowloadprogress: listItem.downloadProgress
                                color: "#826858"
                                opacity:0.8
                                radius: 4
                                anchors.left:parent.left
                                anchors.top:parent.top
                                anchors.bottom: parent.bottom
                                width: dowloadprogress * parent.width
                                visible: (model.is_dir || dowloadprogress <= 0.0||dowloadprogress==1) ? 0 : 1
                                Behavior on width {
                                    NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                }
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: 15
                                //添加到收藏列表
                                HoverButton {
                                    visible:!model.is_dir
                                    image_path: "qrc:/sources/image/我喜欢的.svg"
                                    onClicked: { 
										selectCollect.open(ASMRPlayer.get_path()+model.name); 
                                    }
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                HoverButton {
                                    visible:!model.is_dir
                                    image_path: "qrc:/sources/image/下载.svg"
                                    onClicked: {
                                        ASMRPlayer.download_sign_path("/" + ASMRPlayer.get_path()+model.name);
                                    }
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                //非音频，仅显示文件夹样式图标
                                HoverButton {
                                    visible:model.is_dir
                                    image_path: "qrc:/sources/image/文件夹.svg"
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    Layout.alignment: Qt.AlignVCenter
                                    can_hover:false
                                }
                                Text {
                                    text: model.name
                                    font.pixelSize: 16
                                    color: currentPlaying === ASMRPlayer.get_path()+model.name ? theme.green : theme.fontColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.leftMargin: 0
                                }

                            }
                            HoverButton {
                                anchors.right: parent.right
                                anchors.rightMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                visible:(listItem.downloadProgress!=0)&&(listItem.downloadProgress!=1)
                                image_path: "qrc:/sources/image/取消下载.svg"
                                onClicked: {
                                    dowloadmgr.candelDownload("/" + ASMRPlayer.get_path()+model.name);
                                }
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }


                    }
                    Connections {
                        target: dowloadmgr
                        function onDownloadProgressUpdated(url, progress) {
                            const currentUrl = "/" + ASMRPlayer.get_path()+model.name;
                            if (url === currentUrl) {
                                listItem.downloadProgress = progress;
                            }
                        }
                    }
                    
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
                anchors.centerIn:loadingOverlay
                size: 50
                x: 150
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
