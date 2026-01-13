import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QuickVLC
import QtQuick.Controls.Basic
Item {
    id: seekController
    required property MediaPlayer mediaPlayer
    property alias busy: slider.pressed

    implicitHeight: 20

    function formatToMinutes(milliseconds) {
        if (!milliseconds || milliseconds < 0) {
            milliseconds = 0;
        }
        const min = Math.floor(milliseconds / 60000);
        const sec = Math.floor((milliseconds - min * 60000) / 1000);
        return `${min}:${sec.toString().padStart(2, 0)}`;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 22

        
        Text {
            id: currentTime
            Layout.preferredWidth: 45
            text: seekController.formatToMinutes(seekController.mediaPlayer.position)
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 11
            color:theme.fontColor
        }
        

        Slider {
            id: slider
            Layout.fillWidth: true
            implicitHeight:20
          
            enabled: seekController.mediaPlayer.seekable
            value: seekController.mediaPlayer.position / seekController.mediaPlayer.duration
            
            onMoved: seekController.mediaPlayer.position=(value * seekController.mediaPlayer.duration)
            background:Rectangle{
                height:slider.availableHeight
                width:slider.availableWidth
                radius:10
                color:"white"
                anchors.verticalCenter:parent.verticalCenter
                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: theme.green
                    radius: 2
                }

            }
            handle: Rectangle {
                anchors.verticalCenter:parent.verticalCenter
                x: slider.visualPosition * (slider.availableWidth - width)
                y: slider.availableHeight / 2 - height / 2
                implicitWidth: 18
                implicitHeight: 18
                radius: 13
                color: slider.pressed ? "#f0f0f0" : "#f6f6f6"
                border.color: "#bdbebf"
            }
        }

       
        Text {
            id: remainingTime
            Layout.preferredWidth: 45
            text: seekController.formatToMinutes(seekController.mediaPlayer.duration)
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 11
            color:theme.fontColor
        }
      
    }
}
