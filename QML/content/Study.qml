import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtMultimedia
import com.asmr.player 1.0  // 导入单例模块
pragma ComponentBehavior: Bound

Item {
    id: study
    opacity: 0
    property var file: "/中文音声/婉儿别闹/测试文件夹"

    // 核心修改：生成带索引的结构化路径数组（自带index和name）
    property var pathParts: {
        var rawParts = file.split('/').filter(part => part !== "");
        rawParts.unshift("主页"); // 开头加主页
        var structuredParts = [];
        for (var i = 0; i < rawParts.length; i++) {
            structuredParts.push({
                index: i,       // 自带下标
                name: rawParts[i] // 路径段名称
            });
        }
        return structuredParts;
    }

    Row {
        anchors.fill: parent
        spacing: 2
        Text{text:file;color:"white"} // 调试用

        Repeater {
            // 遍历带索引的结构化数组
            model: study.pathParts
            delegate: row
        }

        Component {
            id: row
            Row {
                // 接收Repeater传递的结构化数据（index+name）
                required property var modelData
               
                spacing: 2

                Text {
                    id: folderText
                    color: "white"
                    // 直接用modelData.name获取路径名（无需再查数组）
                    text: modelData.name
                    font.underline: mouseArea.containsMouse

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // 构建新路径（用modelData.index遍历）
                            var newPath = "";
                            for (var i = 0; i <= modelData.index; i++) {
                                if (i === 0 && pathParts[i].name === "主页") {
                                    newPath = "/";
                                } else if (i === 1) {
                                    newPath += pathParts[i].name;
                                } else if (i > 1) {
                                    newPath += "/" + pathParts[i].name;
                                }
                            }

                            // 更新根文件路径 + 调用接口
                            file = modelData.index === 0 ? "/" : newPath;
                            ASMRPlayer.asmr_list(file, 1, false);
                        }
                    }
                }

                // 分隔符：用modelData.index判断是否最后一项
                Text {
                    color: "white"
                    text: modelData.index < pathParts.length - 1 ? "/" : ""
                    visible: modelData.index < pathParts.length - 1
                }
            }
        }
    }
}