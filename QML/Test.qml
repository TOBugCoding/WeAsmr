import QtQuick
import QtQuick.Controls
import "components"  // 确保这个路径指向你的 EDataTable.qml 所在目录

Item {
    width: 800
    height: 600

    ListModel {
        id: tableModel
        // 初始化测试数据
        ListElement { name: "张三"; age: 25; address: "北京市朝阳区建国路88号"; checked: false }
        ListElement { name: "李四"; age: 30; address: "上海市浦东新区张江高科技园区"; checked: false }
        ListElement { name: "王五"; age: 28; address: "广州市天河区珠江新城"; checked: false }
    }

    EDataTable {
        anchors.centerIn: parent
        width: 700
        height: 400

        headers: [
            { key: "name", label: "姓名" },
            { key: "age", label: "年龄" },
            { key: "address", label: "地址" }
        ]

        model: tableModel
        selectable: true
        headerHeight: 45          // 表头高度
        rowHeight: 40             // 行高度
        fontSize: 15              // 字体大小
        radius: 10                // 圆角大小
        checkmarkColor: "#4CAF50" // 复选框颜色（改为绿色）

        // 信号处理 - 行点击事件
        onRowClicked: {
            console.log("点击了第", index, "行，数据：", JSON.stringify(rowData))
        }

        // 信号处理 - 复选框状态变化事件
        onCheckStateChanged: {
            console.log("第", index, "行复选框状态变为：", isChecked)
            console.log("该行数据：", JSON.stringify(rowData))
        }
    }
}
