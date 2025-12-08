import QtQuick
import QtQuick.Layouts
import "./components" as Components

Flow {
    spacing: 16
   
    Components.EMusicPlayer {
        id: musicPlayer
        // 直接传递全局音乐窗口的打开方法（单参数：源组件）
        openWindowHandler: musicAnimationWindow.openFrom
    }

  
}



