// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic
Item {
    id: audioController

    property alias busy: slider.pressed
    //! [0]
    property alias muted: muteButton.checked
    property real volume: slider.value
    //! [0]
    property alias showSlider: slider.visible
    property int iconDimension: 24
    property var slider_duraiton:100
    implicitHeight: 46
    implicitWidth: mainLayout.width

    RowLayout {
        id: mainLayout
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        RoundButton {
            id: muteButton
            implicitHeight: 36
            implicitWidth: 36
            radius: 4
            icon.source: audioController.muted ? "../images/volume_mute.svg" : "../images/volume.svg"
            icon.width: audioController.iconDimension
            icon.height: audioController.iconDimension
            icon.color:theme.fontColor
            flat: true
            checkable: true
            background: Rectangle {
                color: "transparent"
                MouseArea{
                    anchors.fill:parent
                    hoverEnabled:true
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        Slider {
            id: slider
            visible: !audioController.showSlider
            implicitWidth: audioController.slider_duraiton
            implicitHeight:20
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            enabled: !audioController.muted
            value: 1
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
       
    }
}
