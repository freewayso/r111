# Sol2 Demo - DLL 快速修复脚本
# 自动将 lua54.dll 复制到所有可能的输出目录

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sol2 Demo - DLL 快速修复" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot
$luaDll = Join-Path $projectRoot "lua\lib\lua54.dll"

# 检查 DLL 是否存在
if (-not (Test-Path $luaDll)) {
    Write-Host "错误：找不到 lua54.dll" -ForegroundColor Red
    Write-Host "路径：$luaDll" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ 找到 lua54.dll: $luaDll" -ForegroundColor Green
Write-Host ""

# 定义所有可能的输出目录
$outputDirs = @(
    "build_vs2022\Debug",
    "build_vs2022\Release",
    "build_vs2022\x64\Debug",
    "build_vs2022\x64\Release",
    "build_vs2022\Win32\Debug",
    "build_vs2022\Win32\Release"
)

$copiedCount = 0
$createdCount = 0

foreach ($dir in $outputDirs) {
    $fullPath = Join-Path $projectRoot $dir
    
    # 如果目录不存在，创建它
    if (-not (Test-Path $fullPath)) {
        Write-Host "创建目录：$dir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        $createdCount++
    }
    
    # 复制 DLL
    $destDll = Join-Path $fullPath "lua54.dll"
    try {
        Copy-Item $luaDll -Destination $destDll -Force
        Write-Host "✓ 已复制到：$dir" -ForegroundColor Green
        $copiedCount++
    } catch {
        Write-Host "✗ 复制失败：$dir - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "完成！" -ForegroundColor Green
Write-Host "  创建目录：$createdCount" -ForegroundColor White
Write-Host "  复制文件：$copiedCount" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Yellow
Write-Host "1. 打开 Visual Studio" -ForegroundColor White
Write-Host "2. 在解决方案资源管理器中，右键点击 'sol2_demo' 项目" -ForegroundColor White
Write-Host "3. 选择 '设为启动项目'" -ForegroundColor White
Write-Host "4. 按 F5 运行程序" -ForegroundColor White
Write-Host ""

