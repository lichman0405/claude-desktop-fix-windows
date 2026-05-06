# ============================================================
# Claude Cowork 3P 工作区启动失败 - 增强版一键修复脚本 v2.0
# 自动识别用户名 + 包标识符 | 详细日志 + 高可读性
# ============================================================

Clear-Host
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Claude Cowork 3P 工作区启动失败 - 增强修复脚本 v2.0     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
Write-Host "[检查] 正在验证管理员权限..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ 错误：请右键 PowerShell → 以管理员身份运行此脚本！" -ForegroundColor Red
    Write-Host "按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}
Write-Host "✅ 已确认以管理员身份运行`n" -ForegroundColor Green

# ============================================================
# 步骤 1: 关闭 Claude Desktop 相关进程
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "步骤 1/5：正在关闭 Claude Desktop 及相关进程..." -ForegroundColor Cyan

$processes = @("Claude", "cowork-svc", "Claude Desktop")
foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ 已终止进程: $proc" -ForegroundColor Green
    }
}
Start-Sleep -Seconds 2
Write-Host "✅ 进程清理完成`n" -ForegroundColor Green

# ============================================================
# 步骤 2: 删除旧的虚拟机文件（强制重建）
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "步骤 2/5：正在删除旧的虚拟机缓存文件..." -ForegroundColor Cyan

$basePath = "$env:LOCALAPPDATA\Claude-3p"
$deleted = $false

if (Test-Path "$basePath\vm_bundles") {
    Remove-Item -Recurse -Force "$basePath\vm_bundles" -ErrorAction SilentlyContinue
    Write-Host "  ✓ 已删除: vm_bundles" -ForegroundColor Green
    $deleted = $true
}
if (Test-Path "$basePath\claude-code-vm") {
    Remove-Item -Recurse -Force "$basePath\claude-code-vm" -ErrorAction SilentlyContinue
    Write-Host "  ✓ 已删除: claude-code-vm" -ForegroundColor Green
    $deleted = $true
}

if (-not $deleted) {
    Write-Host "  ℹ️ 未找到旧文件（可能是首次修复）" -ForegroundColor Yellow
}
Write-Host "✅ 旧文件清理完成`n" -ForegroundColor Green

# ============================================================
# 步骤 3: 自动获取包标识符
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "步骤 3/5：正在自动检测 Claude Desktop 包标识符..." -ForegroundColor Cyan

$package = Get-ChildItem "$env:LOCALAPPDATA\Packages\" -ErrorAction SilentlyContinue | 
           Where-Object Name -like "Claude_*" | Select-Object -First 1

if (-not $package) {
    Write-Host "❌ 错误：未找到 Claude Desktop 安装包！" -ForegroundColor Red
    Write-Host "请确认已安装最新版 Claude Desktop 后再试。" -ForegroundColor Yellow
    pause
    exit
}

$packageId = $package.Name
Write-Host "✅ 检测成功！包标识符: $packageId`n" -ForegroundColor Green

# ============================================================
# 步骤 4: 创建硬链接（核心修复）
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "步骤 4/5：正在创建硬链接（这是最关键的一步）..." -ForegroundColor Cyan

$realPath = "$basePath\vm_bundles\claudevm.bundle"
$linkPath = "$env:LOCALAPPDATA\Packages\$packageId\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle"

# 创建目标目录
New-Item -ItemType Directory -Path $linkPath -Force | Out-Null
Write-Host "  → 目标目录已创建" -ForegroundColor Gray

$files = @("rootfs.vhdx", "vmlinuz", "initrd", "smol-bin.vhdx", "smol-bin.x64.vhdx")
$success = 0
$skipped = 0

foreach ($file in $files) {
    $source = "$realPath\$file"
    $target = "$linkPath\$file"
    
    if (Test-Path $source) {
        New-Item -ItemType HardLink -Path $target -Target $source -Force | Out-Null
        Write-Host "  ✅ 硬链接创建成功: $file" -ForegroundColor Green
        $success++
    } else {
        Write-Host "  ⚠️ 文件不存在，已跳过: $file" -ForegroundColor Yellow
        $skipped++
    }
}

Write-Host "`n硬链接统计：成功 $success 个，跳过 $skipped 个" -ForegroundColor Cyan

if ($success -eq 0) {
    Write-Host "❌ 错误：未找到任何虚拟机文件！" -ForegroundColor Red
    Write-Host "请先打开 Claude Desktop，让它完成虚拟机下载后再运行此脚本。" -ForegroundColor Yellow
    pause
    exit
}
Write-Host "✅ 硬链接创建完成`n" -ForegroundColor Green

# ============================================================
# 步骤 5: 重启 CoworkVMService 服务
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "步骤 5/5：正在重启 CoworkVMService 服务..." -ForegroundColor Cyan

try {
    Restart-Service CoworkVMService -Force -ErrorAction Stop
    Start-Sleep -Seconds 3
    $service = Get-Service CoworkVMService
    Write-Host "✅ 服务重启成功！当前状态: $($service.Status)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ 服务重启失败（可能需要手动重启）" -ForegroundColor Yellow
}

# ============================================================
# 修复完成
# ============================================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    🎉 修复已完成！                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n【后续操作步骤】" -ForegroundColor Yellow
Write-Host "1. 关闭当前 PowerShell 窗口" -ForegroundColor White
Write-Host "2. 重新打开 Claude Desktop" -ForegroundColor White
Write-Host "3. 尝试开启 Cowork 或 Cowork 3P" -ForegroundColor White
Write-Host "4. 如果还是失败，请再运行一次本脚本`n" -ForegroundColor White

Write-Host "【常见问题】" -ForegroundColor Cyan
Write-Host "- 第一次启动工作区可能需要等待 30 秒 ~ 2 分钟" -ForegroundColor Gray
Write-Host "- 建议修复后重启电脑一次（可选）" -ForegroundColor Gray
Write-Host "- 如需帮助，请保留上面的日志信息`n" -ForegroundColor Gray

Write-Host "按任意键退出..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")