# Sol2 Demo - Visual Studio 2022 配置指南

## 前置要求

1. Visual Studio 2022
2. CMake 3.12+
3. Lua 库

## 方法一：使用 vcpkg 安装 Lua（推荐）

### 1. 安装 vcpkg
```powershell
# 克隆 vcpkg 仓库
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat

# 添加到系统路径（可选）
.\vcpkg integrate install
```

### 2. 安装 Lua
```powershell
vcpkg install lua:x64-windows
```

### 3. 生成 Visual Studio 2022 项目
```powershell
cd F:\sol2_demo\sol2_demo
cmake -S . -B build_vs2022 -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=[vcpkg根目录]/scripts/buildsystems/vcpkg.cmake
```

## 方法二：手动下载 Lua

### 1. 下载 Lua 二进制文件
访问：https://sourceforge.net/projects/luabinaries/files/5.4.2/Windows%20Libraries/Dynamic/

下载：
- `lua-5.4.2_Win64_dllw6_lib.zip`（包含 DLL 和 LIB 文件）
- `lua-5.4.2_Win64_dllw6_lib.zip` 或直接下载包含头文件的版本

### 2. 解压并组织文件
在项目根目录创建以下结构：
```
F:\sol2_demo\sol2_demo\lua\
├── include\
│   ├── lua.h
│   ├── luaconf.h
│   ├── lualib.h
│   ├── lauxlib.h
│   └── lua.hpp
└── lib\
    ├── lua54.lib
    └── lua54.dll
```

### 3. 生成 Visual Studio 2022 项目
```powershell
cd F:\sol2_demo\sol2_demo
cmake -S . -B build_vs2022 -G "Visual Studio 17 2022" -A x64
```

## 打开项目

生成成功后，打开：
```
F:\sol2_demo\sol2_demo\build_vs2022\Sol2Demo.sln
```

## 编译和运行

1. 在 Visual Studio 中打开 `Sol2Demo.sln`
2. 选择 `Debug` 或 `Release` 配置
3. 右键点击 `sol2_demo` 项目 -> 设为启动项目
4. 按 F5 运行

## 注意事项

- 如果使用手动下载的 Lua DLL，需要将 `lua54.dll` 复制到编译输出目录
- 确保 `scripts/demo.lua` 文件在编译输出目录中
- 默认使用 C++17 标准

## 疑难解答

### 链接错误
如果遇到链接错误，检查：
1. Lua 库文件路径是否正确
2. 是否使用了正确的架构（x64）

### 找不到 lua.h
检查 `LUA_INCLUDE_DIR` 是否正确设置。可以在 CMake GUI 中手动设置。

### 运行时找不到 lua54.dll
将 `lua54.dll` 复制到：
- `build_vs2022\Debug\` 或
- `build_vs2022\Release\`

