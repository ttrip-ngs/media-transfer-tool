cmake_minimum_required(VERSION 3.16)
project(media-transfer-qt)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets)

set(SOURCES
    src/main.cpp
    src/MainWindow.cpp
    src/FileListWidget.cpp
    src/SettingsWidget.cpp
)

set(HEADERS
    src/MainWindow.h
    src/FileListWidget.h
    src/SettingsWidget.h
)

add_executable(media-transfer-qt ${SOURCES} ${HEADERS})

target_link_libraries(media-transfer-qt Qt6::Core Qt6::Widgets)

# Copy resources
configure_file(${CMAKE_SOURCE_DIR}/resources/style.qss ${CMAKE_BINARY_DIR}/style.qss COPYONLY)