import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Number 1.0

Rectangle {
    id:root
    width: 800
    height: 600
    opacity:0 //初始透明度为0 动画加载过渡
    color:"#00000000"
    //property var source:"C:/Users/Administrator/Downloads/33525008011-1-192.mp4"
    NumberToChinese {
        id: numberConverter
    }
   
    Item{
        anchors.fill:parent
        anchors.leftMargin:100
         ColumnLayout {
            anchors.fill: parent
            spacing: 10
            ColumnLayout {
                spacing:0
            
                TextField {
                    id: inputField
                    placeholderText: "请输入金额"
                    Layout.fillWidth: true
                    font.pixelSize: 16
                    validator: DoubleValidator {
                        bottom: 0
                        notation: DoubleValidator.StandardNotation
                    }
                    Keys.onReturnPressed: btn.clicked()
                }
            
                Text {
                    Layout.alignment:Qt.AlignCenter
                    id: num_show
                    opacity:0.0
                    text: "结果将显示在这里"
                    font.pixelSize: 18
                    color: "red"
                    ParallelAnimation{
                        id:paraleAnim
                        PropertyAnimation{
                            id:opacity_anim
                            target:num_show
                            property:"opacity"
                            from:0.0
                            to:1.0
                            duration:200
                            easing.type: Easing.OutCubic
                        }
                        ColorAnimation {
                            id: colorAnimation
                            target: num_show
                            property: "color"
                            from: "red"
                            to: "blue"
                            duration: 1000
                        }
                    }
                }
            
                Button {
                    id: btn
                    text: "转换"
                    Layout.alignment: Qt.AlignCenter
                    onClicked: {
                        paraleAnim.start()
                        var num = parseFloat(inputField.text) || 0;
                        num_show.text = numberConverter.GetNumber(num);
                        //proAnim.start()
                        if (recttest.state === "") {
                            recttest.state = "recttest_move";
                        } else {
                            recttest.state = recttest.state === "recttest_move" ? "recttest_move2" : "recttest_move";
                        }
                    }
                }
            
                Rectangle{
                    id:recttest
                    width:200
                    height:30
                    //Layout.alignment:Qt.AlignCenter
                    color:"blue"
                    PropertyAnimation{
                        id:proAnim
                        target:recttest
                        property:"x"
                        from:recttest.x
                        to:recttest.x+200
                        duration:2000
                    }
                    states:[
                            State{
                                name:"recttest_move"
                                PropertyChanges{
                                    target:recttest;x:root.width/2-recttest.width/2;color:"red"
                                }
                            },
                            State{
                                name:"recttest_move2"
                                PropertyChanges{
                                    target:recttest;x:root.width/2-recttest.width/2;color:"green"
                                }
                            }
                    ]
                    transitions: [
                            Transition{
                                from: ""; to: "recttest_move"
                                PropertyAnimation{
                                    duration:100
                                    properties:"x,color"
                                }
                            },
                            Transition{
                                from: "recttest_move"; to: "recttest_move2"
                                PropertyAnimation{duration:300;properties:"color"}
                            },
                            Transition {
                                from: "recttest_move2";to: "recttest_move"
                                PropertyAnimation { duration:300;properties: "color" }  // 仅变色
                            }
                    ]
                }
            }
        
        }
    }
    Component.onCompleted: {
        let value=dataMgr.GetData()
        console.log("数组长度:", value.length)
    
        for (let i = 0; i < value.length; i++) {
            console.log("元素", i, ":", value[i])
        }
    }
}