# Fix All - 一键修复 Sol2 Demo 常见问题
# 自动修复脚本文件复制、DLL 复制等问题

param(
    [switch]$Clean = $false
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sol2 Demo - 自动修复工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 关闭运行中的程序
Write-Host "[1/6] 关闭运行中的程序..." -ForegroundColor Yellow
$process = Get-Process sol2_demo -ErrorAction SilentlyContinue
if ($process) {
    Stop-Process -Name sol2_demo -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Write-Host "  ✓ 已关闭 sol2_demo.exe" -ForegroundColor Green
} else {
    Write-Host "  ✓ 没有运行中的程序" -ForegroundColor Green
}

# 2. 清理（如果指定）
if ($Clean) {
    Write-Host ""
    Write-Host "[2/6] 清理构建目录..." -ForegroundColor Yellow
    if (Test-Path "build_vs2022") {
        Remove-Item "build_vs2022" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ 已清理 build_vs2022" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "[2/6] 跳过清理（使用 -Clean 参数来清理）" -ForegroundColor Gray
}

# 3. 创建必要的目录
Write-Host ""
Write-Host "[3/6] 创建输出目录..." -ForegroundColor Yellow
$dirs = @(
    "build_vs2022\Debug",
    "build_vs2022\Release",
    "build_vs2022\x64\Debug",
    "build_vs2022\x64\Release",
    "saves"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✓ 创建: $dir" -ForegroundColor Green
    }
}

# 4. 复制脚本文件
Write-Host ""
Write-Host "[4/6] 复制脚本文件..." -ForegroundColor Yellow
$scriptDirs = @("build_vs2022\Debug", "build_vs2022\Release", "build_vs2022\x64\Debug", "build_vs2022\x64\Release")

foreach ($dir in $scriptDirs) {
    if (Test-Path $dir) {
        # 删除旧的 scripts 目录
        if (Test-Path "$dir\scripts") {
            Remove-Item "$dir\scripts" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # 复制新的
        Copy-Item "scripts" -Destination "$dir\" -Recurse -Force -ErrorAction SilentlyContinue
        
        if (Test-Path "$dir\scripts\demo.lua") {
            Write-Host "  ✓ 复制到: $dir" -ForegroundColor Green
        } else {
            Write-Host "  ✗ 失败: $dir" -ForegroundColor Red
        }
    }
}

# 5. 复制 DLL 文件
Write-Host ""
Write-Host "[5/6] 复制 DLL 文件..." -ForegroundColor Yellow

if (Test-Path "lua\lib\lua54.dll") {
    $dllDirs = @("build_vs2022\Debug", "build_vs2022\Release", "build_vs2022\x64\Debug", "build_vs2022\x64\Release")
    
    foreach ($dir in $dllDirs) {
        if (Test-Path $dir) {
            Copy-Item "lua\lib\lua54.dll" -Destination "$dir\" -Force -ErrorAction SilentlyContinue
            if (Test-Path "$dir\lua54.dll") {
                Write-Host "  ✓ 复制 lua54.dll 到: $dir" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "  ⚠ lua54.dll 未找到" -ForegroundColor Yellow
    Write-Host "    请确保已正确安装 Lua" -ForegroundColor Yellow
}

# 6. 验证
Write-Host ""
Write-Host "[6/6] 验证安装..." -ForegroundColor Yellow

$errors = 0

# 检查可执行文件
if (Test-Path "build_vs2022\Debug\sol2_demo.exe") {
    Write-Host "  ✓ sol2_demo.exe 存在" -ForegroundColor Green
} else {
    Write-Host "  ✗ sol2_demo.exe 不存在（需要编译）" -ForegroundColor Red
    $errors++
}

# 检查脚本
if (Test-Path "build_vs2022\Debug\scripts\demo.lua") {
    Write-Host "  ✓ 脚本文件已复制" -ForegroundColor Green
} else {
    Write-Host "  ✗ 脚本文件未找到" -ForegroundColor Red
    $errors++
}

# 检查 DLL
if (Test-Path "build_vs2022\Debug\lua54.dll") {
    Write-Host "  ✓ lua54.dll 已复制" -ForegroundColor Green
} else {
    Write-Host "  ✗ lua54.dll 未找到" -ForegroundColor Red
    $errors++
}

# 统计
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($errors -eq 0) {
    Write-Host "✅ 所有检查通过！" -ForegroundColor Green
    Write-Host ""
    Write-Host "现在可以运行程序：" -ForegroundColor Yellow
    Write-Host "  方法 1 (推荐): .\run.ps1" -ForegroundColor White
    Write-Host "  方法 2: cd build_vs2022\Debug; .\sol2_demo.exe" -ForegroundColor Gray
    Write-Host "  方法 3: 在 Visual Studio 中按 F5" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠ 重要: 必须在 Debug 目录中运行，或使用 run.ps1" -ForegroundColor Yellow
} else {
    Write-Host "⚠ 发现 $errors 个问题" -ForegroundColor Yellow
    Write-Host ""
    if (-not (Test-Path "build_vs2022\Debug\sol2_demo.exe")) {
        Write-Host "需要编译项目：" -ForegroundColor Yellow
        Write-Host "  cmake --build build_vs2022 --config Debug" -ForegroundColor White
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 提示
Write-Host "提示：" -ForegroundColor Cyan
Write-Host "  - 使用 .\fix_all.ps1 -Clean 来清理并重建" -ForegroundColor Gray
Write-Host "  - 查看 '常见问题解决.md' 了解更多" -ForegroundColor Gray
Write-Host ""

