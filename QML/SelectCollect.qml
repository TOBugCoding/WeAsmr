import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
import com.asmr.player 1.0 // 引入ASMRPlayer，调用get_all_collections

// 收藏夹选择弹窗 (Popup版本)
Popup {
    id: selectPopup
    // 宽度由最长文本决定，高度保持原有逻辑
    width: maxTextWidth + 40 // +40 预留边距和滚动条空间
    height: folderListView.contentHeight > 200 ? 200 + 20 : folderListView.contentHeight + 20 // 固定高度

    // 对外暴露的属性
    property string selectedFolder: "" // 选中的收藏夹名称（返回值）
    property string defaultSelected: "" // 默认选中的收藏夹名称
    property string msg;
    // 新增属性：存储最长文本的宽度
    property real maxTextWidth: 0

    background: Rectangle {
        color: theme.leftBarColor
        radius: 4
        border.color: theme.borderColor
        border.width: 1
    }


    // 收藏夹列表模型
    ListModel {
        id: folderModel
    }

    function loadModel(){
        let folderList = ASMRPlayer.get_all_collections();
        folderList.reverse();

        // 重置最大文本宽度
        maxTextWidth = 0;

        // 2. 填充列表模型
        folderModel.clear();
        folderList.forEach(folderName => {
            folderModel.append({ name: folderName });

            // 计算当前文本宽度并更新最大值
            let textWidth = calculateTextWidth(folderName, 14);
            if(textWidth > maxTextWidth){
                maxTextWidth = textWidth;
            }
        });
    }

    // 计算指定文本的宽度（字体大小14）
    function calculateTextWidth(text, fontSize) {
        // 创建临时Text对象计算宽度
        let tempText = Qt.createQmlObject(`
            import QtQuick
            Text {
                text: "${text.replace(/"/g, '\\"')}" // 转义双引号避免语法错误
                font.pointSize: ${fontSize}
                visible: false // 不可见，仅用于计算
            }
        `, selectPopup);

        let width = tempText.width;
        tempText.destroy(); // 销毁临时对象释放资源
        return width;
    }

    contentItem: Rectangle {
        color: "transparent"
        anchors.fill: parent
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            ListView {
                id: folderListView
                anchors.fill: parent
                anchors.margins: 10
                boundsBehavior: Flickable.StopAtBounds
                spacing: 5
                ScrollBar.vertical: ScrollBar {
                    anchors.right: parent.right
                    width: 13
                }
                model: folderModel
                clip: true

                delegate: Item {
                    // 列表项宽度适配父容器
                    width: folderListView.width
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
                        // 移除文本省略，确保完整显示
                        elide: Text.ElideNone
                        // 文本宽度自适应内容
                        width: implicitWidth
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: {
                            folderListView.currentIndex = index;
                            selectPopup.selectedFolder = model.name;
                        }
                        onClicked: {
                            selectPopup.close();
                            leftbar.collect_add_message=selectPopup.selectedFolder
                            ASMRPlayer.collect_audio(selectPopup.selectedFolder, selectPopup.msg);
                        }
                    }
                }
            }
        }
    }

    // 打开弹窗
    function open(_msg) {
        // 加载收藏夹
        loadModel();
        selectPopup.msg = _msg;

        // 获取全局鼠标位置
        let globalMousePos = mousePosition.cursorPos();

        // 将全局坐标转换为相对于父组件的坐标
        let localPos = selectPopup.parent.mapFromGlobal(globalMousePos.x, globalMousePos.y);

        // 计算弹窗位置
        let dialogH = selectPopup.height; // 弹窗自身高度
        let dialogW = selectPopup.width;  // 弹窗宽度

        // 计算位置：鼠标右侧偏移30像素
        let posX = localPos.x + 30;
        let posY = localPos.y - dialogH / 2;

        // 边界检测，确保不超出父窗口
        if (posX + dialogW > selectPopup.parent.width) {
            posX = localPos.x - dialogW - 10; // 显示在鼠标左侧
        }
        if (posY < 0) {
            posY = 0;
        } else if (posY + dialogH > selectPopup.parent.height) {
            posY = selectPopup.parent.height - dialogH;
        }

        // 设置位置
        selectPopup.x = posX;
        selectPopup.y = posY;

        // 显示弹窗
        selectPopup.visible = true;
    }
}
