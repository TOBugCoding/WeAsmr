cmake_minimum_required(VERSION 3.16)

project(QtQuickDemo VERSION 0.1 LANGUAGES CXX)

# Qt自动处理MOC/RCC（禁用AUTOUIC，因为是Qt Quick）
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC OFF)

# C++标准
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 优先搜索当前目录（适配MOC/UI生成文件）
set(CMAKE_INCLUDE_CURRENT_DIR ON)


find_package(Qt6 6.9 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    Network
)


set(SRC_FILES
    src/main.cpp
    src/netMusic.cpp
    src/fpscounter.cpp
    src/DownloadTool.cpp
    qml.qrc
)

set(HEADER_FILES
    include/netMusic.h
    include/fpscounter.h
    include/CursorPosProvider.h
    include/DownloadTool.h
    include/DownloadToolMgr.h
    include/downloadm3u8.h include/downloadm3u8.cpp
)

set(APP_ICON_RESOURCE_WINDOWS "${CMAKE_CURRENT_SOURCE_DIR}/icon.rc")


qt6_add_executable(WeAsmrPlayer WIN32
    ${SRC_FILES}
    ${HEADER_FILES}
    ${APP_ICON_RESOURCE_WINDOWS}
)

# 指定头文件搜索路径（现代写法，推荐）
target_include_directories(WeAsmrPlayer
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# 链接Qt库
target_link_libraries(WeAsmrPlayer PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
    "E:/QT/6.9.3/msvc2022_64/lib/libvlc.lib"
    "E:/QT/6.9.3/msvc2022_64/lib/libvlccore.lib"
    "E:/QT/6.9.3/msvc2022_64/lib/QuickVLCCore.lib"
    "E:/QT/6.9.3/msvc2022_64/lib/QuickVLCQml.lib"
)

# 可选：安装规则（如果需要打包发布）
# install(TARGETS QtQuickDemo
#     BUNDLE DESTINATION .
#     LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#     RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
# )
