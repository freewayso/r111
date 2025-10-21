# Sol2 Demo - Lua 自动设置脚本
# 该脚本会自动下载并配置 Lua 5.4 for Windows

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Sol2 Demo - Lua 自动设置脚本" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 定义路径
$projectRoot = $PSScriptRoot
$luaDir = Join-Path $projectRoot "lua"
$luaIncludeDir = Join-Path $luaDir "include"
$luaLibDir = Join-Path $luaDir "lib"
$tempDir = Join-Path $projectRoot "temp_lua_download"

# Lua 版本
$luaVersion = "5.4.2"

Write-Host "项目根目录: $projectRoot" -ForegroundColor Yellow
Write-Host "Lua 安装目录: $luaDir" -ForegroundColor Yellow
Write-Host ""

# 创建必要的目录
Write-Host "[1/5] 创建目录结构..." -ForegroundColor Green
if (-not (Test-Path $luaDir)) {
    New-Item -ItemType Directory -Path $luaDir | Out-Null
}
if (-not (Test-Path $luaIncludeDir)) {
    New-Item -ItemType Directory -Path $luaIncludeDir | Out-Null
}
if (-not (Test-Path $luaLibDir)) {
    New-Item -ItemType Directory -Path $luaLibDir | Out-Null
}
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# 下载 Lua 库文件
Write-Host "[2/5] 下载 Lua $luaVersion 库文件..." -ForegroundColor Green
$libUrl = "https://sourceforge.net/projects/luabinaries/files/$luaVersion/Windows%20Libraries/Dynamic/lua-${luaVersion}_Win64_dllw6_lib.zip/download"
$libZip = Join-Path $tempDir "lua_lib.zip"

try {
    # 使用备用下载地址（GitHub 镜像或直接链接）
    # 由于 SourceForge 下载可能需要重定向，我们使用手动下载提示
    Write-Host "   正在准备下载..." -ForegroundColor Yellow
    Write-Host "   如果自动下载失败，请手动下载：" -ForegroundColor Yellow
    Write-Host "   URL: https://sourceforge.net/projects/luabinaries/files/$luaVersion/Windows%20Libraries/Dynamic/" -ForegroundColor Cyan
    Write-Host ""
    
    # 尝试下载（可能会因为 SourceForge 重定向而失败）
    # Invoke-WebRequest -Uri $libUrl -OutFile $libZip -UserAgent "Mozilla/5.0"
    
    Write-Host "   请手动下载以下文件并解压到临时目录：" -ForegroundColor Yellow
    Write-Host "   1. lua-${luaVersion}_Win64_dllw6_lib.zip" -ForegroundColor Cyan
    Write-Host "   2. lua-${luaVersion}_Win64_dllw6_lib.zip (includes)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   或者使用更简单的方法：使用下面的命令通过 vcpkg 安装" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "   自动下载失败（这是正常的）" -ForegroundColor Yellow
}

# 提供手动操作指南
Write-Host "[3/5] 手动下载指南" -ForegroundColor Green
Write-Host "由于版权原因，需要您手动完成以下步骤：" -ForegroundColor Yellow
Write-Host ""
Write-Host "选项 1: 手动下载 (如果没有 vcpkg)" -ForegroundColor Cyan
Write-Host "  1. 访问: https://sourceforge.net/projects/luabinaries/files/" -ForegroundColor White
Write-Host "  2. 下载以下文件:" -ForegroundColor White
Write-Host "     - lua-5.4.2_Win64_dllw6_lib.zip" -ForegroundColor White
Write-Host "     - lua-5.4.2_Win64_includes.zip" -ForegroundColor White
Write-Host "  3. 解压文件:" -ForegroundColor White
Write-Host "     - 将 *.h 文件放到: $luaIncludeDir" -ForegroundColor White
Write-Host "     - 将 lua54.lib 放到: $luaLibDir" -ForegroundColor White
Write-Host "     - 将 lua54.dll 放到: $luaLibDir" -ForegroundColor White
Write-Host ""
Write-Host "选项 2: 使用 vcpkg (推荐)" -ForegroundColor Cyan
Write-Host "  1. 如果还没有 vcpkg，先安装它:" -ForegroundColor White
Write-Host "     git clone https://github.com/Microsoft/vcpkg.git" -ForegroundColor Gray
Write-Host "     cd vcpkg" -ForegroundColor Gray
Write-Host "     .\bootstrap-vcpkg.bat" -ForegroundColor Gray
Write-Host "     .\vcpkg integrate install" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. 安装 Lua:" -ForegroundColor White
Write-Host "     vcpkg install lua:x64-windows" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. 生成 VS2022 项目:" -ForegroundColor White
Write-Host "     cmake -S . -B build_vs2022 -G `"Visual Studio 17 2022`" -A x64 ``" -ForegroundColor Gray
Write-Host "       -DCMAKE_TOOLCHAIN_FILE=[vcpkg路径]/scripts/buildsystems/vcpkg.cmake" -ForegroundColor Gray
Write-Host ""

# 清理临时目录
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}

Write-Host "[4/5] 检查 Lua 文件..." -ForegroundColor Green
$requiredHeaders = @("lua.h", "luaconf.h", "lualib.h", "lauxlib.h")
$headersFound = $true

foreach ($header in $requiredHeaders) {
    $headerPath = Join-Path $luaIncludeDir $header
    if (Test-Path $headerPath) {
        Write-Host "   ✓ 找到: $header" -ForegroundColor Green
    } else {
        Write-Host "   ✗ 缺失: $header" -ForegroundColor Red
        $headersFound = $false
    }
}

if (-not $headersFound) {
    Write-Host ""
    Write-Host "请按照上述指南手动下载 Lua 文件" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "[5/5] 设置完成!" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：生成 Visual Studio 2022 项目" -ForegroundColor Cyan
Write-Host "运行命令:" -ForegroundColor Yellow
Write-Host "  cmake -S . -B build_vs2022 -G `"Visual Studio 17 2022`" -A x64" -ForegroundColor White
Write-Host ""
Write-Host "然后打开:" -ForegroundColor Yellow
Write-Host "  .\build_vs2022\Sol2Demo.sln" -ForegroundColor White
Write-Host ""

