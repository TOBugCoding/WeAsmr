cmake_minimum_required(VERSION 3.16)

project(QtQuickDemo VERSION 0.1 LANGUAGES CXX)

# 打开 Qt 必需的自动处理
set(CMAKE_AUTOMOC ON)      # 让 moc 自动跑
set(CMAKE_AUTORCC ON)      # 让 rcc 自动跑
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---------- FFmpeg ----------
set(FFMPEG_ROOT "D:/c++packages/ffmpeg-7.1.1-full_build-shared")
find_path(FFMPEG_INCLUDE_DIR
    NAMES libavformat/avformat.h
    PATHS "${FFMPEG_ROOT}/include"
    NO_DEFAULT_PATH
)
set(FFMPEG_LIB_DIR     "${FFMPEG_ROOT}/lib")
link_directories(${FFMPEG_LIB_DIR})
# 找 Qt6组件
find_package(Qt6 6.9 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia network)

# 把源文件一次性收进来
file(GLOB_RECURSE SRC_FILES
     ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h)   # 头文件也列进来，moc 会扫描
# 把 qrc 加进去
qt6_add_resources(SRC_FILES qml.qrc)

# 生成可执行文件
 qt_add_executable(QtQuickDemo WIN32 ${SRC_FILES})

#导出
#qt_add_executable(QtQuickDemo  ${SRC_FILES})
# 包含目录
target_include_directories(QtQuickDemo
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${FFMPEG_INCLUDE_DIR}
)
# 链接库
target_link_libraries(QtQuickDemo PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Multimedia Qt6::Network
    ${FFMPEG_LIB}
    avdevice.lib
    avformat.lib
    avcodec.lib
    avutil.lib
    swscale.lib
    swresample.lib
    avfilter.lib
)


