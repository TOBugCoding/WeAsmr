import QtQuick
import QtQuick.Effects
import QtQuick.Controls.Basic
Rectangle {
	id:rootHoverButton
	color:"transparent"
	width:20;height:20
    property string image_path:""
	property bool isExpanded: false  // 记录当前状态，控制图标切换	
    property var m_rotation:0.0
	property var bright:theme.globalBrightness
    property bool can_hover:true
	signal clicked 
	signal doubleclicked
	signal entered
	Image {
		id:sourceIcon
		anchors.fill:parent
		source: rootHoverButton.image_path
		visible:false
	}
	MultiEffect {
		id: arrowEffect
		source: sourceIcon
		anchors.fill: sourceIcon
		brightness:theme.globalBrightness
		colorization:0
		colorizationColor:theme.globalColor
		transform: Rotation {
			angle: rootHoverButton.m_rotation
			// 确保旋转中心在元素中心
			origin.x: arrowEffect.width / 2
			origin.y: arrowEffect.height / 2
		}
	}
	MouseArea{
		visible:rootHoverButton.can_hover
		id: mouseArea	
		anchors.fill: parent	
		hoverEnabled:true 
		propagateComposedEvents: true //开启后，子mousearea的点击会传递给父
        cursorShape: Qt.PointingHandCursor//手型
		default property Item content: null
		onEntered: {
			arrowEffect.brightness=1;
			arrowEffect.colorization = 1;
			rootHoverButton.entered()
		}
		onExited: {
			arrowEffect.brightness=rootHoverButton.bright;//底层纯白后再上色
			arrowEffect.colorization = 0;
		}
		onClicked:{
			rootHoverButton.clicked()
		}
		onDoubleClicked:{
			rootHoverButton.doubleclicked()
		}
		Item {
            id: contentItem
            anchors.fill: parent
        }
	}
	onBrightChanged:{
		arrowEffect.brightness=rootHoverButton.bright;
		arrowEffect.colorization = 0;
	}
	function btn_clear(){
		//按钮不可点击时的样式
		//console.log("修改为不可点击")
		arrowEffect.brightness=rootHoverButton.bright/3
		mouseArea.enabled=false
		mouseArea.cursorShape = Qt.ArrowCursor; 
	}
	function btn_restor(){
		//按钮可点击时的样式
		//console.log("修改为可点击")
		arrowEffect.brightness=rootHoverButton.bright
		mouseArea.enabled=true
		mouseArea.cursorShape = Qt.PointingHandCursor;
	}	
}
