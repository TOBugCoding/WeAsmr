import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import NetMusic 1.0

Item {
    id: root
    width: 400
    height: 600
    function search(keyword){
        musicSearcher.searchMusic(keyword)
    }
    opacity: 0
    property var searchResults: []
    property string statusMessage: ""

    NetMusic {
        id: musicSearcher

        onSearchResultReady:(resultList) => {
            root.searchResults = resultList
            root.statusMessage = resultList.length > 0 ? "" : "没有找到匹配的歌曲。"
        }

        onErrorOccurred:(errorString) => {
            root.statusMessage = errorString
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        Text {
            text: root.statusMessage
            color: "red"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        ListView {
            width:parent.width
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.searchResults
            boundsBehavior: Flickable.StopAtBounds
            spacing: 8
            clip: true
            delegate: Rectangle {
                width: parent.width
                height: 60
                color:"#000000000"
                // 将 MouseArea 移到这里，作为 Rectangle 的直接子项
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("点击歌曲：", modelData.songname, " 歌手：", modelData.singer)
                        musicSearcher.playMusic("http://ws.stream.qqmusic.qq.com/C400001pNZFJ4Luwsm.m4a")
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Image {
                        id: albumImage
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        // 增加对无效 albumid 的判断
                        source: modelData.albumid && modelData.albumid !== "0"
                            ? "http://imgcache.qq.com/music/photo/album_300/" + (modelData.albumid % 100) + "/300_albumpic_" + modelData.albumid + "_0.jpg"
                            : "qrc:/sources/image/desktop.svg" // 请确保此路径下有默认图片
                        fillMode: Image.PreserveAspectFit
                        clip: true
                        // 加载失败时也显示默认图片
                       
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Text {
                            text: modelData.songname || "未知歌曲"
                            font.bold: true
                            font.pointSize: 14
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "歌手: " + (modelData.singer || "未知歌手")
                            font.pointSize: 11
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
         
        }
    }
   
}