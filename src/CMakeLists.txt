cmake_minimum_required(VERSION 3.10.2)
project("silero_vad")
set(CMAKE_SYSTEM_NAME Android)
set(CMAKE_SYSTEM_VERSION 21) # API level
set(CMAKE_ANDROID_ARCH_ABI arm64-v8a) # ABI
set(CMAKE_ANDROID_NDK C:/Users/fshuu/AppData/Local/Android/Sdk/ndk/25.2.9519653)
set(CMAKE_ANDROID_STL_TYPE c++_shared)

include_directories(onnxruntime/include/)
link_directories(onnxruntime/lib/)

set(SOURCES vad_library.cpp
            vad_interface.h
            vad_iterator.cpp
            )
            
add_library(silero_vad SHARED ${SOURCES})
target_link_libraries(silero_vad onnxruntime)
set_target_properties(silero_vad PROPERTIES INSTALL_RPATH "onnxruntime/lib/")