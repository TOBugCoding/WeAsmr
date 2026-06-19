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
    id: collectPage
    property string currentPlaying: ""
    property string currentCollectFile:ASMRPlayer.get_collect_file()
    property string dislike_ensure_path:""
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
                    name: audioList[i].split("/").pop(),
                    is_dir: false
                });
            }
            //console.log("收藏夹加载完成，共" + audioList.length + "首音频");
        }
        function onCollect_file_changed(){collectPage.currentCollectFile=ASMRPlayer.get_collect_file()}
        function onCurrent_playing_changed(){
            collectPage.currentPlaying=ASMRPlayer.get_current_playing();
        }
    }

    MessageBox {
        id: collectDetail
        set_flag:0+1
        onEnsure:{
            ASMRPlayer.delete_collection(collectPage.currentCollectFile)
            ASMRPlayer.set_collect_file("默认收藏夹")
        }
    }
    MessageBox {
        id: dislicke_ensure
        set_flag:0+1
        onEnsure:{
            ASMRPlayer.dislike_collect_audio(collectPage.currentCollectFile,collectPage.dislike_ensure_path);
            //刷新收藏夹
            ASMRPlayer.set_collect_file(collectPage.currentCollectFile,true)
        }
    }
    FileDialog {
        id: fileDialog
        title: "选择要添加的音频资源"
        currentFolder: "file:///" + appDir + "/download"
        onAccepted:{
            ASMRPlayer.collect_audio(ASMRPlayer.get_collect_file(),fileDialog.selectedFile);
            //qml刷新数据
            ASMRPlayer.load_audio(ASMRPlayer.get_collect_file());
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
                id:sequence_btn
                anchors.top:collect_title.bottom
                anchors.topMargin:20
                image_path:"qrc:/sources/image/调整顺序.svg";
                onClicked:{
                    ASMRPlayer.load_audio(ASMRPlayer.get_collect_file(),true);
                }
            }
            HoverButton{
                id:load_local_audio
                anchors.top:collect_title.bottom
                anchors.topMargin:20
                anchors.left:sequence_btn.right
                anchors.leftMargin: 20
                width: 22
                height: 22
                image_path:"qrc:/sources/image/导入.svg"
                onClicked:{
                    fileDialog.open()
                }
            }
            HoverButton{
                anchors.top:collect_title.bottom
                anchors.topMargin:20
                anchors.left:load_local_audio.right
                anchors.leftMargin: 20
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
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.leftMargin:50
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        ListView {
            id: asmrshow_list
            width: parent.width
            height: parent.height-50
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
                itemName: model.name
                downloadUrl: "/" + model.audioPath
                cancelUrl: "/" + model.audioPath
                currentPlaying: collectPage.currentPlaying
                playingComparePath: model.audioPath
                mouseAcceptedButtons: Qt.LeftButton | Qt.RightButton

                handleClick: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        contextMenu.audioPath = model.audioPath
                        contextMenu.audioName = model.name
                        contextMenu.popupAt(mouse)
                        return
                    }
                    const name = String(model.name)
                    if (name.indexOf(".") === -1) return
                    var isMedia = MediaUtils.isMediaFile(model.name)
                    let isSameFile = (currentPlaying === model.audioPath)
                    if (!isMedia) {
                        ASMRPlayer.get_sign_path(model.audioPath)
                        return
                    }
                    currentPlaying = model.audioPath
                    ASMRPlayer.set_current_playing(model.audioPath)
                    if (!isSameFile) {
                        var audioSiteId = ASMRPlayer.getAudioSiteId(collectPage.currentCollectFile, model.audioPath)
                        var currentSiteId = ASMRPlayer.currentSiteId()
                        if (audioSiteId && audioSiteId !== currentSiteId) {
                            ASMRPlayer.switchToSite(audioSiteId)
                            var siteCfg = configMgr.getSiteConfig()
                            configMgr.saveSiteConfig(siteCfg.serverUrl || "", audioSiteId)
                            configMgr.saveSites(ASMRPlayer.getSitesJson())
                        }
                        ASMRPlayer.get_sign_path(model.audioPath)
                        let targetLrc = model.name.split(".").slice(0, -1).join(".") + ".lrc"
                        if (targetLrc === model.name) return
                        for (var i = 0; i < audioListModel.count; i++) {
                            var item = audioListModel.get(i)
                            if (item.name === targetLrc) {
                                ASMRPlayer.download_vlc_path(item.audioPath)
                                return
                            }
                        }
                        ASMRPlayer.show_vlc(false)
                    }
                }

                HoverButton {
                    visible: !model.is_dir
                    image_path: "qrc:/sources/image/加号.svg"
                    onClicked: {
                        contextMenu.audioPath = model.audioPath
                        contextMenu.audioName = model.name
                        contextMenu.x = 0; contextMenu.y = 0
                        contextMenu.open()
                    }
                    width: 24; height: 24
                }
                HoverButton {
                    visible: !model.is_dir && !model.audioPath.startsWith("file:///")
                    image_path: "qrc:/sources/image/下载.svg"
                    onClicked: ASMRPlayer.download_sign_path("/" + model.audioPath, "/" + model.audioPath)
                    width: 24; height: 24
                }
            }
        }

        // 操作菜单
        Popup {
            id: contextMenu
            property string audioPath: ""
            property string audioName: ""
            width: 160
            padding: 10
            background: Rectangle {
                color: theme.leftBarColor
                radius: 4
                border.color: theme.contentColor
                border.width: 1
            }

            contentItem: Column {
                id: menuColumn
                spacing: 2

                Repeater {
                    model: ListModel {
                        ListElement { name: "移动到..."; action: "move" }
                        ListElement { name: "复制到..."; action: "copy" }
                        ListElement { name: "取消收藏"; action: "remove" }
                    }
                    delegate: Rectangle {
                        required property string name
                        required property string action
                        required property int index
                        width: menuColumn.width
                        height: 32
                        radius: 4
                        color: menuItemMouse.containsMouse ? Qt.rgba(theme.globalColor.r, theme.globalColor.g, theme.globalColor.b, 0.2) : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: name
                            color: action === "remove" ? "#FF6B6B" : theme.fontColor
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: menuItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                contextMenu.close()
                                if (action === "move") {
                                    moveCopyDialog.mode = "move"
                                    moveCopyDialog.audioPath = contextMenu.audioPath
                                    moveCopyDialog.audioName = contextMenu.audioName
                                    moveCopyDialog.currentFolder = ASMRPlayer.get_collect_file()
                                    moveCopyDialog.open()
                                } else if (action === "copy") {
                                    moveCopyDialog.mode = "copy"
                                    moveCopyDialog.audioPath = contextMenu.audioPath
                                    moveCopyDialog.audioName = contextMenu.audioName
                                    moveCopyDialog.currentFolder = ASMRPlayer.get_collect_file()
                                    moveCopyDialog.open()
                                } else if (action === "remove") {
                                    collectPage.dislike_ensure_path = contextMenu.audioPath
                                    dislicke_ensure.text = "确认取消收藏"
                                    dislicke_ensure.open()
                                }
                            }
                        }
                    }
                }
            }

            function popupAt(mouse) {
                // 获取全局鼠标位置
                let globalMousePos = mousePosition.cursorPos()
                // 将全局坐标转换为相对于父组件的坐标
                let localPos = parent.mapFromGlobal(globalMousePos.x, globalMousePos.y)
                // 计算位置
                let posX = localPos.x + 10
                let posY = localPos.y - height / 2
                // 边界检测
                if (posX + width > parent.width) posX = localPos.x - width - 10
                if (posY < 0) posY = 0
                if (posY + height > parent.height) posY = parent.height - height
                x = posX
                y = posY
                open()
            }
        }

        // 移动/复制对话框
        Popup {
            id: moveCopyDialog
            property string mode: ""  // "move" or "copy"
            property string audioPath: ""
            property string audioName: ""
            property string currentFolder: ""
            width: 300
            height: 350
            parent: Overlay.overlay
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            modal: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            onOpened: {
                // 实时加载收藏夹列表
                loadFolderList()
            }

            function loadFolderList() {
                var folders = ASMRPlayer.get_all_collections()
                folderListModel.clear()
                for (var i = 0; i < folders.length; i++) {
                    folderListModel.append({"folderName": folders[i]})
                }
            }

            background: Rectangle {
                color: theme.leftBarColor
                radius: 8
                border.color: theme.contentColor
                border.width: 1
            }

            contentItem: Item {
                anchors.fill: parent

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: moveCopyDialog.mode === "move" ? "移动到收藏夹" : "复制到收藏夹"
                        color: theme.fontColor
                        font.pointSize: 14
                        font.bold: true
                    }

                    Text {
                        text: "音频: " + moveCopyDialog.audioName
                        color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.7)
                        font.pointSize: 11
                        width: parent.width
                        elide: Text.ElideMiddle
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: theme.contentColor
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - 70
                        clip: true
                        spacing: 4
                        model: ListModel { id: folderListModel }

                        delegate: Rectangle {
                            required property string folderName
                            required property int index
                            width: parent.width
                            height: 36
                            radius: 4
                            color: folderMouse.containsMouse ? Qt.rgba(theme.globalColor.r, theme.globalColor.g, theme.globalColor.b, 0.2) : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: folderName
                                color: folderName === moveCopyDialog.currentFolder ? theme.green : theme.fontColor
                                font.pixelSize: 13
                            }

                            Text {
                                visible: folderName === moveCopyDialog.currentFolder
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: "(当前)"
                                color: theme.green
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: folderMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (folderName === moveCopyDialog.currentFolder) return

                                    if (moveCopyDialog.mode === "move") {
                                        ASMRPlayer.moveAudio(moveCopyDialog.currentFolder, folderName, moveCopyDialog.audioPath)
                                    } else {
                                        ASMRPlayer.copyAudio(moveCopyDialog.currentFolder, folderName, moveCopyDialog.audioPath)
                                    }
                                    moveCopyDialog.close()
                                    // 刷新列表
                                    ASMRPlayer.load_audio(ASMRPlayer.get_collect_file())
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
        collectPage.currentPlaying=ASMRPlayer.get_current_playing()
        ASMRPlayer.load_audio(ASMRPlayer.get_collect_file());
        loadingOverlay.visible = (audioListModel.count === 0);
    }
}
