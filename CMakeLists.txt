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

# 查找Qt6模块（修正network为Network）
find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    Multimedia
    Network
)

# 拆分源文件/头文件（更清晰）
set(SRC_FILES
    src/main.cpp
    src/netMusic.cpp
    src/fpscounter.cpp
    #src/logger.cpp
    qml.qrc  # 资源文件归类到源文件
)

set(HEADER_FILES
    include/netMusic.h
    include/fpscounter.h
    include/CursorPosProvider.h
    #include/logger.h
)

# 生成可执行文件（WIN32用于Windows隐藏控制台）
qt6_add_executable(QtQuickDemo WIN32
    ${SRC_FILES}
    ${HEADER_FILES}  # 仅用于IDE显示
)

# 指定头文件搜索路径（现代写法，推荐）
target_include_directories(QtQuickDemo
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# 链接Qt库
target_link_libraries(QtQuickDemo PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Qt6::Network
)

# 可选：安装规则（如果需要打包发布）
# install(TARGETS QtQuickDemo
#     BUNDLE DESTINATION .
#     LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#     RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
# )
