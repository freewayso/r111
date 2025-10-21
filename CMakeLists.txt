cmake_minimum_required(VERSION 3.12)
project(Sol2Demo)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 添加 sol2 头文件路径
include_directories(${CMAKE_SOURCE_DIR})

# Find Protobuf
set(protobuf_MODULE_COMPATIBLE ON)
find_package(Protobuf CONFIG)
if(Protobuf_FOUND)
    message(STATUS "Protobuf found: ${Protobuf_VERSION}")
    include_directories(${Protobuf_INCLUDE_DIRS})
    include_directories(${CMAKE_CURRENT_BINARY_DIR})
else()
    message(WARNING "Protobuf not found. Install via: vcpkg install protobuf")
    message(WARNING "Project will compile without protobuf support")
endif()

# 根据平台配置 Lua
if(WIN32)
    # Windows 平台 - 尝试查找 Lua
    find_package(Lua)
    
    if(LUA_FOUND)
        message(STATUS "Found Lua via find_package: ${LUA_LIBRARIES}")
        include_directories(${LUA_INCLUDE_DIR})
    else()
        message(STATUS "Lua not found by find_package")
        
        # 尝试使用本地 lua 文件夹
        if(EXISTS "${CMAKE_SOURCE_DIR}/lua/include")
            set(LUA_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/lua/include")
            set(LUA_LIBRARIES "${CMAKE_SOURCE_DIR}/lua/lib/lua54.lib")
            message(STATUS "Using local Lua: ${LUA_INCLUDE_DIR}")
        else()
            message(WARNING "Lua not found! Please either:")
            message(WARNING "  1. Install via vcpkg: vcpkg install lua")
            message(WARNING "  2. Download from: https://sourceforge.net/projects/luabinaries/")
            message(WARNING "  3. Extract to ${CMAKE_SOURCE_DIR}/lua/ with include/ and lib/ subdirectories")
            
            # 设置默认路径，但标记为未找到
            set(LUA_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/lua/include" CACHE PATH "Lua include directory")
            set(LUA_LIBRARIES "${CMAKE_SOURCE_DIR}/lua/lib/lua54.lib" CACHE FILEPATH "Lua library")
        endif()
        
        if(LUA_INCLUDE_DIR AND EXISTS "${LUA_INCLUDE_DIR}")
            include_directories(${LUA_INCLUDE_DIR})
        endif()
    endif()
else()
    # Linux/Unix 平台
    include_directories(/usr/include/lua5.3)
    set(LUA_LIBRARIES /usr/lib/x86_64-linux-gnu/liblua5.3.a)
endif()

# Generate protobuf files
if(Protobuf_FOUND)
    set(PROTO_FILES
        proto/game_data.proto
    )
    
    protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${PROTO_FILES})
    
    # Add generated files to sources
    set(PROTOBUF_SOURCES ${PROTO_SRCS} ${PROTO_HDRS})
else()
    set(PROTOBUF_SOURCES "")
endif()

add_executable(sol2_demo
    src/main.cpp
    src/game_engine.cpp
    src/game_engine.hpp
    ${PROTOBUF_SOURCES}
)

# 链接 Lua 库
target_link_libraries(sol2_demo ${LUA_LIBRARIES})

# 链接 Protobuf 库
if(Protobuf_FOUND)
    target_link_libraries(sol2_demo protobuf::libprotobuf)
    target_compile_definitions(sol2_demo PRIVATE USE_PROTOBUF)
    message(STATUS "Protobuf enabled with static linking")
endif()

# Windows 平台额外配置
if(WIN32)
    # 将 lua54.dll 复制到可执行文件目录
    if(EXISTS "${CMAKE_SOURCE_DIR}/lua/lib/lua54.dll")
        add_custom_command(TARGET sol2_demo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_SOURCE_DIR}/lua/lib/lua54.dll"
                "$<TARGET_FILE_DIR:sol2_demo>/lua54.dll"
            COMMENT "Copying lua54.dll to output directory"
        )
    endif()
endif()

# 复制脚本文件到构建目录
add_custom_command(TARGET sol2_demo POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_SOURCE_DIR}/scripts"
        "$<TARGET_FILE_DIR:sol2_demo>/scripts"
    COMMENT "Copying scripts to output directory"
)














































