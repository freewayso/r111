# Run Sol2 Demo - 启动脚本
# 自动切换到正确的工作目录并运行程序

param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sol2 Demo - 启动脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$exePath = "build_vs2022\$Config\sol2_demo.exe"

# 检查可执行文件是否存在
if (-not (Test-Path $exePath)) {
    Write-Host "错误: 找不到 $exePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先编译项目：" -ForegroundColor Yellow
    Write-Host "  cmake --build build_vs2022 --config $Config" -ForegroundColor White
    Write-Host ""
    Write-Host "或运行修复脚本：" -ForegroundColor Yellow
    Write-Host "  .\fix_all.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

# 检查脚本文件是否存在
if (-not (Test-Path "build_vs2022\$Config\scripts\demo.lua")) {
    Write-Host "警告: 脚本文件未找到，正在复制..." -ForegroundColor Yellow
    Copy-Item "scripts" -Destination "build_vs2022\$Config\" -Recurse -Force
    Write-Host "✓ 脚本文件已复制" -ForegroundColor Green
    Write-Host ""
}

# 检查 DLL 是否存在
if (-not (Test-Path "build_vs2022\$Config\lua54.dll")) {
    Write-Host "警告: lua54.dll 未找到，正在复制..." -ForegroundColor Yellow
    if (Test-Path "lua\lib\lua54.dll") {
        Copy-Item "lua\lib\lua54.dll" -Destination "build_vs2022\$Config\" -Force
        Write-Host "✓ lua54.dll 已复制" -ForegroundColor Green
    } else {
        Write-Host "错误: lua\lib\lua54.dll 不存在" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

Write-Host "启动程序 ($Config 模式)..." -ForegroundColor Green
Write-Host "工作目录: build_vs2022\$Config\" -ForegroundColor Gray
Write-Host ""
Write-Host "提示：" -ForegroundColor Cyan
Write-Host "  - 按 'R' 手动重载脚本" -ForegroundColor Gray
Write-Host "  - 按 'A' 切换自动重载" -ForegroundColor Gray
Write-Host "  - 按 'Q' 退出程序" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 切换到正确的目录并运行
Set-Location "build_vs2022\$Config"
& ".\sol2_demo.exe"

# 返回原目录
Set-Location "../.."

