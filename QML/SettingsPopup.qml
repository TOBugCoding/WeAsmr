// SettingsPopup.qml — 设置弹窗（站点管理 + 服务器配置 + kkfileview）
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import com.asmr.player 1.0
Popup {
    id: settingsPop
    width: 420
    height: 520
    property Item parentItem: null  // 由 TopBar 设置 parent
    parent: parentItem
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 3 : 0
    property bool deleteMode: false

    onOpened: {
        deleteMode = false
        var siteCfg = configMgr.getSiteConfig()
        var url = siteCfg.serverUrl || ""
        if (url.indexOf("://") !== -1) {
            url = url.split("://")[1]
        }
        var parts = url.split(":")
        serverHostInput.text = parts[0] || ""
        serverPortInput.text = parts[1] || "8080"
        serverStatus.text = ""
        siteListView.model = ASMRPlayer.siteNames()
        siteListView.currentIndex = ASMRPlayer.currentSiteIndex()
        kkfileInput.text = configMgr.getKkfileServer() || ""
        kkfileStatus.text = ""
    }

    background: Rectangle {
        color: "#00000000"
    }

    // ===== 分区标题组件 =====
    component SectionHeader: Rectangle {
        property string text: ""
        property bool showDeleteBtn: false
        width: parent.width
        height: 36
        color: theme.leftBarColor

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            Text {
                text: parent.parent.text
                color: theme.fontColor
                font.pointSize: 11
                font.bold: true
                Layout.fillWidth: true
            }
            Rectangle {
                visible: parent.parent.showDeleteBtn
                width: 24; height: 24; radius: 4
                color: settingsPop.deleteMode ? "#FF6B6B" : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: iconFont.name
                    font.pixelSize: 11
                    color: settingsPop.deleteMode ? "white" : Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.5)
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsPop.deleteMode = !settingsPop.deleteMode
                }
            }
        }
        Rectangle { height: 1; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; color: theme.contentColor }
    }

    contentItem: Item {
        // 标题栏
        Rectangle {
            id: settingsHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48
            color: theme.leftBarColor
            topLeftRadius: 15
            topRightRadius: 15
            z: 10

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                Text {
                    text: "设置"
                    color: theme.fontColor
                    font.pointSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }
                HoverButton {
                    image_path: "qrc:/sources/image/close.svg"
                    onClicked: settingsPop.close()
                }
            }
        }

        Rectangle { height: 1; anchors.top: settingsHeader.bottom; anchors.left: parent.left; anchors.right: parent.right; color: theme.contentColor }

        // 可滚动内容区域
        Flickable {
            anchors.top: settingsHeader.bottom
            anchors.topMargin: 1
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            contentHeight: settingsContent.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { width: 6 }

            Column {
                id: settingsContent
                width: parent.width

                // ===== 1. 站点列表 =====
                SectionHeader { text: "选择站点"; showDeleteBtn: true }

                Rectangle {
                    width: parent.width
                    height: Math.min(siteListView.contentHeight + 16, 200)
                    color: theme.leftBarColor
                    ListView {
                        id: siteListView
                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true
                        spacing: 4
                        model: ASMRPlayer.siteNames()
                        currentIndex: ASMRPlayer.currentSiteIndex()

                        delegate: Rectangle{
                            required property string modelData
                            required property int index
                            width: siteListView.width
                            height: 40
                            radius: 4
                            color: index === siteListView.currentIndex ? theme.globalColor
                                 : siteMouse.containsMouse ? Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.1)
                                 : "transparent"

                            RowLayout{
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8
                                Text{
                                    text: modelData
                                    font.pixelSize: 13
                                    color: index === siteListView.currentIndex ? "white" : theme.fontColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text{
                                    visible: index === siteListView.currentIndex && !settingsPop.deleteMode
                                    text: ""
                                    font.family: iconFont.name
                                    font.pixelSize: 13
                                    color: "white"
                                }
                                Rectangle{
                                    visible: settingsPop.deleteMode
                                    width: 22; height: 22; radius: 11
                                    color: deleteMouse.containsMouse ? "#FF6B6B" : Qt.rgba(1,0,0,0.15)
                                    Text{
                                        anchors.centerIn: parent
                                        text: ""
                                        font.family: iconFont.name
                                        font.pixelSize: 10
                                        color: deleteMouse.containsMouse ? "white" : "#FF6B6B"
                                    }
                                    MouseArea{
                                        id: deleteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            confirmDelete.siteId = ASMRPlayer.siteIdByIndex(index)
                                            confirmDelete.siteName = modelData
                                            confirmDelete.open()
                                        }
                                    }
                                }
                            }
                            MouseArea{
                                id: siteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !settingsPop.deleteMode
                                onClicked: {
                                    ASMRPlayer.setSiteByIndex(index)
                                    var siteCfg = configMgr.getSiteConfig()
                                    configMgr.saveSiteConfig(siteCfg.serverUrl || "", ASMRPlayer.currentSiteId())
                                    configMgr.saveSites(ASMRPlayer.getSitesJson())
                                    settingsPop.close()
                                    leftbar.thisQml = "qrc:/QML/content/Asmr_list.qml"
                                    leftbar.current_list_view = "ASMR"
                                    leftbar.force_fresh = 1
                                }
                            }
                        }
                        Connections {
                            target: ASMRPlayer
                            function onSitesReceived() {
                                siteListView.model = ASMRPlayer.siteNames()
                                siteListView.currentIndex = ASMRPlayer.currentSiteIndex()
                            }
                            function onCurrentSiteChanged() {
                                siteListView.currentIndex = ASMRPlayer.currentSiteIndex()
                            }
                        }
                    }
                }

                // ===== 2. 添加站点 =====
                SectionHeader { text: "添加站点" }

                Rectangle {
                    width: parent.width
                    height: addSiteColumn.height + 32
                    color: theme.leftBarColor
                    Column {
                        id: addSiteColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16
                        spacing: 10

                        Column{
                            width: parent.width; spacing: 4
                            Text{ text: "站点名称"; color: theme.fontColor; font.pointSize: 10 }
                            Rectangle{
                                width: parent.width; height: 32; radius: 4; color: theme.contentColor
                                border.color: siteIdInput.activeFocus ? theme.green : Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.15)
                                border.width: 1
                                TextInput{
                                    id: siteIdInput; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter; color: theme.fontColor; font.pixelSize: 13; clip: true
                                    Text{ visible: !siteIdInput.text && !siteIdInput.activeFocus; text: "例: mySite"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.3); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Column{
                            width: parent.width; spacing: 4
                            Text{ text: "主域名"; color: theme.fontColor; font.pointSize: 10 }
                            Rectangle{
                                width: parent.width; height: 32; radius: 4; color: theme.contentColor
                                border.color: siteUrlInput.activeFocus ? theme.green : Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.15)
                                border.width: 1
                                TextInput{
                                    id: siteUrlInput; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter; color: theme.fontColor; font.pixelSize: 13; clip: true
                                    Text{ visible: !siteUrlInput.text && !siteUrlInput.activeFocus; text: "例: https://asmrmoon.com"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.3); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Text{ id: addStatus; text: ""; color: theme.green; font.pointSize: 9; width: parent.width; wrapMode: Text.Wrap }
                        Rectangle{
                            width: parent.width; height: 32; radius: 4; color: theme.globalColor
                            Text{ anchors.centerIn: parent; text: "添加"; color: "white"; font.pointSize: 10 }
                            MouseArea{
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var name = siteIdInput.text.trim(); var url = siteUrlInput.text.trim()
                                    if(!name || !url){ addStatus.text = "请填写完整"; addStatus.color = "#FF6B6B"; return }
                                    if(url.indexOf("://") === -1){ url = "https://" + url }
                                    var id = name.replace(/\s+/g, "")
                                    var ok = ASMRPlayer.addSite(id, name, url)
                                    if(ok){
                                        configMgr.saveSites(ASMRPlayer.getSitesJson())
                                        siteIdInput.text = ""; siteUrlInput.text = ""
                                        addStatus.text = "添加成功"; addStatus.color = theme.green
                                    } else { addStatus.text = "添加失败，请检查输入"; addStatus.color = "#FF6B6B" }
                                }
                            }
                        }
                        Text{ text: "手动添加的站点会在服务器同步时保留。"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.4); font.pointSize: 9; width: parent.width; wrapMode: Text.Wrap }
                    }
                }

                // ===== 3. 服务器设置 =====
                SectionHeader { text: "服务器设置" }

                Rectangle {
                    width: parent.width
                    height: serverColumn.height + 32
                    color: theme.leftBarColor
                    Column {
                        id: serverColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16
                        spacing: 10

                        Column{
                            width: parent.width; spacing: 4
                            Text{ text: "IP / 域名"; color: theme.fontColor; font.pointSize: 10 }
                            Rectangle{
                                width: parent.width; height: 36; radius: 4; color: theme.contentColor
                                border.color: serverHostInput.activeFocus ? theme.green : Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.15)
                                border.width: 1
                                TextInput{
                                    id: serverHostInput; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter; color: theme.fontColor; font.pixelSize: 14; clip: true
                                    Text{ visible: !serverHostInput.text && !serverHostInput.activeFocus; text: "例: 192.168.1.100"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.3); font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Column{
                            width: parent.width; spacing: 4
                            Text{ text: "端口"; color: theme.fontColor; font.pointSize: 10 }
                            Rectangle{
                                width: 120; height: 36; radius: 4; color: theme.contentColor
                                border.color: serverPortInput.activeFocus ? theme.green : Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.15)
                                border.width: 1
                                TextInput{
                                    id: serverPortInput; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter; color: theme.fontColor; font.pixelSize: 14; clip: true
                                    validator: IntValidator { bottom: 1; top: 65535 }
                                    Text{ visible: !serverPortInput.text && !serverPortInput.activeFocus; text: "8080"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.3); font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Text{ id: serverStatus; text: ""; color: theme.green; font.pointSize: 9; width: parent.width; wrapMode: Text.Wrap }
                        Row{
                            spacing: 12
                            Rectangle{
                                width: testBtn.implicitWidth + 24; height: 32; radius: 4; color: theme.contentColor; border.color: theme.green; border.width: 1
                                Text{ id: testBtn; anchors.centerIn: parent; text: "测试连接"; color: theme.green; font.pointSize: 10 }
                                MouseArea{
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var host = serverHostInput.text.trim(); var port = serverPortInput.text.trim() || "8080"
                                        if(!host){ serverStatus.text = "请输入地址"; serverStatus.color = "#FF6B6B"; return }
                                        var url = "http://" + host + ":" + port
                                        serverStatus.text = "连接中..."; serverStatus.color = theme.fontColor
                                        ASMRPlayer.setSiteServer(url)
                                        var siteCfg = configMgr.getSiteConfig()
                                        configMgr.saveSiteConfig(url, siteCfg.lastSelected || ASMRPlayer.currentSiteId())
                                        ASMRPlayer.syncSites()
                                    }
                                }
                            }
                            Rectangle{
                                width: saveBtn.implicitWidth + 24; height: 32; radius: 4; color: theme.globalColor
                                Text{ id: saveBtn; anchors.centerIn: parent; text: "保存"; color: "white"; font.pointSize: 10 }
                                MouseArea{
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var host = serverHostInput.text.trim(); var port = serverPortInput.text.trim() || "8080"
                                        var url = host ? ("http://" + host + ":" + port) : ""
                                        var siteCfg = configMgr.getSiteConfig()
                                        configMgr.saveSiteConfig(url, siteCfg.lastSelected || ASMRPlayer.currentSiteId())
                                        if(url){ ASMRPlayer.setSiteServer(url); ASMRPlayer.syncSites() }
                                        serverStatus.text = "已保存"; serverStatus.color = theme.green
                                    }
                                }
                            }
                        }
                        Text{ text: "设置远程服务器地址后，站点列表将从服务器同步获取。留空则使用内置列表。"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.4); font.pointSize: 9; width: parent.width; wrapMode: Text.Wrap }
                    }
                }

                // ===== 4. 预览服务器设置 =====
                SectionHeader { text: "预览服务器 (kkfileview)" }

                Rectangle {
                    width: parent.width
                    height: kkfileColumn.height + 32
                    color: theme.leftBarColor
                    bottomLeftRadius: 15
                    bottomRightRadius: 15
                    Column {
                        id: kkfileColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16
                        spacing: 10

                        Column{
                            width: parent.width; spacing: 4
                            Text{ text: "服务器地址"; color: theme.fontColor; font.pointSize: 10 }
                            Rectangle{
                                width: parent.width; height: 36; radius: 4; color: theme.contentColor
                                border.color: kkfileInput.activeFocus ? theme.green : Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.15)
                                border.width: 1
                                TextInput{
                                    id: kkfileInput; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter; color: theme.fontColor; font.pixelSize: 14; clip: true
                                    Text{ visible: !kkfileInput.text && !kkfileInput.activeFocus; text: "http://47.96.159.221:8012"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.3); font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Text{ id: kkfileStatus; text: ""; color: theme.green; font.pointSize: 9; width: parent.width; wrapMode: Text.Wrap }
                        Row{
                            spacing: 12
                            Rectangle{
                                width: kkfileTestBtn.implicitWidth + 24; height: 32; radius: 4; color: theme.contentColor; border.color: theme.green; border.width: 1
                                Text{ id: kkfileTestBtn; anchors.centerIn: parent; text: "测试连接"; color: theme.green; font.pointSize: 10 }
                                MouseArea{
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var server = kkfileInput.text.trim()
                                        if(!server){ kkfileStatus.text = "请输入地址"; kkfileStatus.color = "#FF6B6B"; return }
                                        kkfileStatus.text = "功能开发中..."; kkfileStatus.color = theme.fontColor
                                    }
                                }
                            }
                            Rectangle{
                                width: kkfileSaveBtn.implicitWidth + 24; height: 32; radius: 4; color: theme.globalColor
                                Text{ id: kkfileSaveBtn; anchors.centerIn: parent; text: "保存"; color: "white"; font.pointSize: 10 }
                                MouseArea{
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var server = kkfileInput.text.trim()
                                        if(!server){ server = "http://47.96.159.221:8012" }
                                        configMgr.saveKkfileServer(server)
                                        kkfileStatus.text = "已保存"; kkfileStatus.color = theme.green
                                    }
                                }
                            }
                        }
                        Text{ text: "设置 kkfileview 文件预览服务地址，用于在线预览非音视频文件。"; color: Qt.rgba(theme.fontColor.r, theme.fontColor.g, theme.fontColor.b, 0.4); font.pointSize: 9; width: parent.width; wrapMode: Text.Wrap }
                    }
                }

                // 底部间距
                Item { width: 1; height: 16 }
            }
        }
    }

    // 删除确认对话框
    Popup{
        id: confirmDelete
        property string siteId: ""
        property string siteName: ""
        width: 300
        height: 140
        parent: settingsPop.contentItem
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        background: Rectangle{
            color: theme.leftBarColor
            radius: 8
            border.color: theme.contentColor
            border.width: 1
        }
        contentItem: Column{
            anchors.centerIn: parent
            spacing: 16
            Text{
                anchors.horizontalCenter: parent.horizontalCenter
                text: "确定删除 \"" + confirmDelete.siteName + "\" ？"
                color: theme.fontColor
                font.pointSize: 12
            }
            Row{
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16
                Rectangle{
                    width: 80; height: 30; radius: 4
                    color: theme.contentColor
                    Text{ anchors.centerIn: parent; text: "取消"; color: theme.fontColor; font.pointSize: 10 }
                    MouseArea{ anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: confirmDelete.close() }
                }
                Rectangle{
                    width: 80; height: 30; radius: 4
                    color: "#FF6B6B"
                    Text{ anchors.centerIn: parent; text: "删除"; color: "white"; font.pointSize: 10 }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ASMRPlayer.removeSite(confirmDelete.siteId)
                            configMgr.saveSites(ASMRPlayer.getSitesJson())
                            var siteCfg = configMgr.getSiteConfig()
                            if(siteCfg.lastSelected === confirmDelete.siteId){
                                configMgr.saveSiteConfig(siteCfg.serverUrl || "", ASMRPlayer.currentSiteId())
                            }
                            confirmDelete.close()
                        }
                    }
                }
            }
        }
    }

    Connections{
        target: ASMRPlayer
        function onSitesReceived(){
            serverStatus.text = "同步成功"
            serverStatus.color = theme.green
            configMgr.saveSites(ASMRPlayer.getSitesJson())
        }
        function onSitesSyncFailed(error){
            serverStatus.text = "同步失败: " + error
            serverStatus.color = "#FF6B6B"
        }
    }
}
