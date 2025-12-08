import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs
import com.asmr.player 1.0
import "."
pragma ComponentBehavior: Bound

Item{
	id:leftBar
	//property var source:"https://mooncdn.asmrmoon.com/中文音声/婉儿别闹/餐厅与望春楼小剧场.flac?sign=nEM47MH3hoG2K8X6zzptJUOqKz3y2zVKZhnl4_Wj_UQ=:0"
	property var leftBarData:[
		{headerText:"在线音频",btnData:[
			{btnText:"ASMR",btnIcon:"qrc:/sources/image/我喜欢的.svg",qml:"qrc:/QML/content/Asmr_list.qml",isActive:true},
			{btnText:"关于我",btnIcon:"qrc:/sources/image/视频.svg",qml:"qrc:/QML/content/Aboutme.qml",isActive:true},
			],isActive:true,addAble:false},
		{headerText:"我的音乐",btnData:[
			{btnText:"音乐组件",btnIcon:"qrc:/sources/image/我喜欢的.svg",qml:"qrc:/QML/content/Music.qml",isActive:true},
			{btnText:"转中文",btnIcon:"qrc:/sources/image/音乐馆.svg",qml:"qrc:/QML/content/NumberToChinese.qml",isActive:true},
            {btnText:"tcp学习",btnIcon:"qrc:/sources/image/视频.svg",qml:"qrc:/QML/content/TcpStudy.qml",isActive:true},
			{btnText:"基础组件",btnIcon:"qrc:/sources/image/音乐馆.svg",qml:"qrc:/QML/content/BaseShow.qml",isActive:true},
			],isActive:false,addAble:false},
		{headerText:"收藏列表",btnData:[],isActive:true,addAble:true},
		]
	property var current_list_view:""//记录当前选择的选项
	property var collect_add_message:""//记录哪个收藏夹多了内容
	property bool isCreatingCollection: false
	function filterLeftBarData(leftBarData) {
		return leftBarData
			.filter(item => item && item.isActive)          
			.map(item => ({
				headerText: item.headerText,
				btnData:    item.btnData.filter(btn => btn && btn.isActive),
				addAble:	item.addAble
			}));
	}
	function generateCollectionBtnData(collectionNames) {
		let btnData = [];
		for (let i = 0; i < collectionNames.length; i++) {
			btnData.push({
				btnText: collectionNames[i],  
				btnIcon: "",                 
				qml: "qrc:/QML/content/Collect.qml", 
				isActive: true,
				addAble:true
			});
		}
		btnData.reverse();
		return btnData;
	}
	// 封装收藏夹列表刷新逻辑（复用初始化逻辑）
	function refreshCollectionList() {
		let collectionNames = ASMRPlayer.get_all_collections();
		let collectionBtnData = generateCollectionBtnData(collectionNames);
		// 更新收藏列表的btnData
		for (let i = 0; i < leftBarData.length; i++) {
			if (leftBarData[i].headerText === "收藏列表") {
				leftBarData[i].btnData = collectionBtnData;
				break;
			}
		}
		// 重新过滤数据 + 刷新Repeater
		thisData = filterLeftBarData(leftBarData);
		leftBarRepeater.model = thisData;
		console.log("收藏夹列表已刷新，当前列表：", collectionNames);
	}
	property var thisData: filterLeftBarData(leftBarData)
	property var child: bot_player
	property var left_btn_list:left_btn_list
	property string thisQml:"qrc:/QML/content/Asmr_list.qml"
	property string thisBtnText:""
	property int count:thisData.length
	property int btnHeight:40
	property int btnWidth:130
	property int fronts:11
	property int collect_fonts:10
	property int fontSize:9
	Connections {
        target: ASMRPlayer
		function onCollectChanged(){
			// 刷新收藏夹列表
			leftBar.refreshCollectionList();
		}
	}
	MessageBox {
        id: leftbarDetail
    }
	Row{
		id: rootRow
		anchors.fill: parent
		
		Item {
			id:left_btn_list
			width: leftBar.btnWidth*1.5
            height: parent.height
			visible: true

			Rectangle{
				anchors.fill:parent
				color:theme.leftBarColor
				opacity:theme.opacity
			}
			MouseArea {
				width: parent.width
				height: parent.height
				hoverEnabled: true
				onEntered: {
					ver_bar.opacity = 1
				}
				onExited: {
				    ver_bar.opacity = 0
				}
				onPressed:{parent.forceActiveFocus()}
				Flickable{
					id:leftBarFlickable
					width: parent.width
					height: parent.height
					contentWidth: width
					contentHeight: leftColumn.implicitHeight
					boundsBehavior: Flickable.StopAtBounds
					clip: true
                    acceptedButtons:Qt.NoButton
					leftMargin:30
					ScrollBar.vertical:ScrollBar{
						id:ver_bar
						anchors.right: parent.right
						policy:ScrollBar.AsNeeded
						width:13
						background: Rectangle {
							id:scrollBarBg
							color: "transparent"
							radius: 4
						}
						contentItem: Rectangle {
							id: scrollHandle
							color: "gray"
							radius: 4
							opacity:0.8
							MouseArea {
								hoverEnabled: true
								anchors.fill: parent
								onEntered: scrollHandle.color = "white"
								onExited: scrollHandle.color = "gray"
								onPressed: function(mouse){
									mouse.accepted = false}
							}
						}
						opacity:0
						onPositionChanged:{parent.forceActiveFocus()}
					}
					Column{
						id: leftColumn
						topPadding:10
						spacing:leftBar.btnHeight
						Repeater{
							id:leftBarRepeater
							model:leftBar.thisData
							delegate:repeaterDelegate
						}
					}
					Component {
						id: repeaterDelegate
						Item { 
							width: listview.width
							height: visible ? listview.height : 0
							required property var modelData
							ListView {
								id: listview
								width: leftBarFlickable.width
								height: contentHeight
								interactive: false
								spacing:4
								clip:true
								model: modelData.btnData
								property bool isExpanded: false
								header:Column{
									RowLayout{
										Item{
											Layout.fillWidth: true 
											Layout.preferredWidth: parent.width * 0.08
										}
										Text{
											Layout.fillWidth: true 
											font.pointSize:leftBar.fontSize
											text:modelData.headerText
											height:modelData.headerText==""?0:contentHeight
											color:theme.samllTitleColor
											MouseArea {
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onEntered:{parent.color=theme.green}
												onExited:{parent.color=Qt.binding(function() { return theme.samllTitleColor })}
												onClicked:{list_dynamic_btn.clicked()}
											}
										}
										Item{
											Layout.fillWidth: true 
											Layout.preferredWidth: modelData.addAble?parent.width * 0.18:parent.width * 0.35 
										}
										// 增加收藏夹逻辑
										// 找到收藏列表的加号按钮，替换onClicked逻辑
										HoverButton{
											visible:modelData.addAble
											image_path: "qrc:/sources/image/加号.svg"
											onClicked:{
												if(listview.isExpanded){list_dynamic_btn.clicked()}
												collect_input_creat.visible=!collect_input_creat.visible
											}
										}
								
										HoverButton{
											id:list_dynamic_btn
											Layout.fillWidth: true 
											image_path:listview.isExpanded 
												? "qrc:/sources/image/icon_line_direction_arrow_up_black.svg" 
												: "qrc:/sources/image/y_icon_line_direction_arrow_down_black.svg"

											onClicked:{
												listview.isExpanded  = !listview.isExpanded ;
												listview.height = (listview.height === leftBar.fontSize*2) 
													? listview.contentHeight+(modelData.addAble?collect_input_creat.height:0)
													: leftBar.fontSize*2;
											}
										}
									}
									Item{
										id:collect_input_creat;
										visible:false;
										width:leftBar.btnWidth;
										height:leftBar.btnHeight;
										property string inputText: "新建收藏夹"
										property string placeholderText: "请输入收藏夹名称"	
										// 防重复触发标记
										property bool isConfirming: false
										// 不用主动消失输入框，重新加载后会自动消失
										function handleConfirm(){
											//如果正在确认中，直接返回
											if(isConfirming) return;
											const trimText = inputField.text.trim();
											if(!trimText) return;
											// 标记为「正在确认」，避免重复执行
											isConfirming = true;
											// 执行创建逻辑
											let folderName = trimText;
											let result=ASMRPlayer.add_collection(folderName);
											if(!result){
												collect_input_creat.visible = false; // 改为直接隐藏，避免重复点击
												leftbarDetail.text="创建失败,已存在文件夹";
												leftbarDetail.open()
											}
										}	
										TextField {
											anchors.fill:parent
											id: inputField
											text: collect_input_creat.inputText
											font.pointSize: 10
									
											onEditingFinished:{
												collect_input_creat.handleConfirm()
											}
										
											onVisibleChanged:{
												if(visible){
													forceActiveFocus();
													inputField.selectAll();
													collect_input_creat.isConfirming = false;
												}
											}
											background: Rectangle {
												implicitWidth: parent.width
												implicitHeight: parent.height
												color: theme.globalColor
												radius:10
											}
										}
										}
									}
								
								delegate: listviewDelegate
							}
						}
					}
					Component{
						id:	listviewDelegate
						Rectangle{
							visible:modelData.isActive
							required property var modelData
							property bool isHoverd:false
							width:leftBar.btnWidth
							height:leftBar.btnHeight
							color:leftBar.current_list_view==modelData.btnText?theme.globalColor:(isHoverd?theme.globalColor:"transparent")
							opacity:theme.opacity
							radius:10
						
							Row{
								leftPadding:10
								anchors.verticalCenter:parent.verticalCenter
								spacing:10
								Image{
									id:pageBtn_image
									source:modelData.btnIcon
									width:20
									anchors.verticalCenter:parent.verticalCenter
									fillMode:Image.PreserveAspectFit
									MultiEffect {
										source: parent
										anchors.fill: parent
										brightness:theme.globalBrightness
									}
									visible:!modelData.addAble
								}
								
								Text{
									Layout.fillWidth: true
									font.pointSize:(modelData.addAble?leftBar.collect_fonts:leftBar.fronts)
									color:theme.fontColor
									text: {
										var maxLen = 9; // 自定义最大可显示字符数
										var rawText = modelData.btnText || ""; // 防止文本为undefined
										if (rawText.length > maxLen) {
											return rawText.substring(0, maxLen) + "…"; // 截断+省略号
											// 若不需要省略号，直接 return rawText.substring(0, maxLen);
										}
										return rawText;
									}
								}
								Text{text:"●";color:"red";font.pointSize:leftBar.collect_fonts;visible:leftBar.collect_add_message==modelData.btnText}
							}
							MouseArea{
								id: mouseArea
								anchors.fill:parent
								hoverEnabled:true
								onEntered:{parent.isHoverd=true;mouseArea.cursorShape = Qt.PointingHandCursor;}
								onExited:{parent.isHoverd=false;mouseArea.cursorShape = Qt.ArrowCursor;}
								onClicked:{
									if(leftBar.collect_add_message==modelData.btnText){
										leftBar.collect_add_message=""
									}
									leftBar.current_list_view=modelData.btnText
									parent.forceActiveFocus()
									ASMRPlayer.set_collect_file(modelData.btnText)
									if(leftBar.thisQml!=modelData.qml){
										leftBar.thisQml=modelData.qml
										topbar.history.push(modelData.qml)
										topbar.now_pos++
										console.log("添加成功",topbar.history,topbar.now_pos)
									}
								}
							}
						}
					}
				}
			}
		}
		
		Item{
			id: rightContentItem
			width: left_btn_list.visible ? (rootRow.width - left_btn_list.width) : rootRow.width
			height: parent.height
			Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
			
			Rectangle{
				color: theme.contentColor
				anchors.fill:parent
				opacity:theme.opacity
			}
			Column{
				id:right_content
				anchors.fill:parent
				Item{
					width:parent.width;
					height:parent.height-bottom_player.height
					opacity:topbar.fullscreen?0:1
					Content {
						clip:false
						id:dynamic_page_content
						thisQml: leftBar.thisQml
					}
				}
				Item{
					z:20
					id:bottom_player
					height:bot_player.implicitHeight
					width:parent.width
					Bottomplayer{id:bot_player;anchors.fill:parent}
				}
			}
		}
	}

	Component.onCompleted: {
		rightContentItem.width = left_btn_list.visible ? (rootRow.width - left_btn_list.width) : rootRow.width;
		// 调用封装的刷新逻辑初始化列表
		refreshCollectionList();
	}
	
}