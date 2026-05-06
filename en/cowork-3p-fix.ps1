# ============================================================
# Claude Cowork 3P Workspace Launch Fix - Enhanced Script v2.0
# Auto-detects username + package identifier | Detailed logging
# ============================================================

Clear-Host
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Claude Cowork 3P Workspace Launch Fix - Script v2.0      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check administrator privileges
Write-Host "[Check] Verifying administrator privileges..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Please right-click PowerShell and select 'Run as Administrator'!" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}
Write-Host "OK - Running as Administrator`n" -ForegroundColor Green

# ============================================================
# Step 1: Kill Claude Desktop related processes
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "Step 1/5: Stopping Claude Desktop and related processes..." -ForegroundColor Cyan

$processes = @("Claude", "cowork-svc", "Claude Desktop")
foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Terminated process: $proc" -ForegroundColor Green
    }
}
Start-Sleep -Seconds 2
Write-Host "OK - Processes cleaned up`n" -ForegroundColor Green

# ============================================================
# Step 2: Delete old VM cache files (force rebuild)
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "Step 2/5: Removing old VM cache files..." -ForegroundColor Cyan

$basePath = "$env:LOCALAPPDATA\Claude-3p"
$deleted = $false

if (Test-Path "$basePath\vm_bundles") {
    Remove-Item -Recurse -Force "$basePath\vm_bundles" -ErrorAction SilentlyContinue
    Write-Host "  [OK] Deleted: vm_bundles" -ForegroundColor Green
    $deleted = $true
}
if (Test-Path "$basePath\claude-code-vm") {
    Remove-Item -Recurse -Force "$basePath\claude-code-vm" -ErrorAction SilentlyContinue
    Write-Host "  [OK] Deleted: claude-code-vm" -ForegroundColor Green
    $deleted = $true
}

if (-not $deleted) {
    Write-Host "  [INFO] No old files found (may be first-time fix)" -ForegroundColor Yellow
}
Write-Host "OK - Old files removed`n" -ForegroundColor Green

# ============================================================
# Step 3: Auto-detect package identifier
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "Step 3/5: Auto-detecting Claude Desktop package identifier..." -ForegroundColor Cyan

$package = Get-ChildItem "$env:LOCALAPPDATA\Packages\" -ErrorAction SilentlyContinue |
           Where-Object Name -like "Claude_*" | Select-Object -First 1

if (-not $package) {
    Write-Host "ERROR: Claude Desktop installation package not found!" -ForegroundColor Red
    Write-Host "Please ensure the latest Claude Desktop is installed and try again." -ForegroundColor Yellow
    pause
    exit
}

$packageId = $package.Name
Write-Host "OK - Package identifier detected: $packageId`n" -ForegroundColor Green

# ============================================================
# Step 4: Create hard links (core fix)
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "Step 4/5: Creating hard links (this is the critical step)..." -ForegroundColor Cyan

$realPath = "$basePath\vm_bundles\claudevm.bundle"
$linkPath = "$env:LOCALAPPDATA\Packages\$packageId\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle"

# Create target directory
New-Item -ItemType Directory -Path $linkPath -Force | Out-Null
Write-Host "  -> Target directory created" -ForegroundColor Gray

$files = @("rootfs.vhdx", "vmlinuz", "initrd", "smol-bin.vhdx", "smol-bin.x64.vhdx")
$success = 0
$skipped = 0

foreach ($file in $files) {
    $source = "$realPath\$file"
    $target = "$linkPath\$file"

    if (Test-Path $source) {
        New-Item -ItemType HardLink -Path $target -Target $source -Force | Out-Null
        Write-Host "  [OK] Hard link created: $file" -ForegroundColor Green
        $success++
    } else {
        Write-Host "  [SKIP] File not found, skipped: $file" -ForegroundColor Yellow
        $skipped++
    }
}

Write-Host "`nHard link summary: $success created, $skipped skipped" -ForegroundColor Cyan

if ($success -eq 0) {
    Write-Host "ERROR: No VM files found!" -ForegroundColor Red
    Write-Host "Please open Claude Desktop first and let it finish downloading the VM, then re-run this script." -ForegroundColor Yellow
    pause
    exit
}
Write-Host "OK - Hard links created`n" -ForegroundColor Green

# ============================================================
# Step 5: Restart CoworkVMService
# ============================================================
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "Step 5/5: Restarting CoworkVMService..." -ForegroundColor Cyan

try {
    Restart-Service CoworkVMService -Force -ErrorAction Stop
    Start-Sleep -Seconds 3
    $service = Get-Service CoworkVMService
    Write-Host "OK - Service restarted successfully! Current status: $($service.Status)" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Service restart failed (may require manual restart)" -ForegroundColor Yellow
}

# ============================================================
# Fix complete
# ============================================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                   Fix Complete!                             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n[Next Steps]" -ForegroundColor Yellow
Write-Host "1. Close this PowerShell window" -ForegroundColor White
Write-Host "2. Reopen Claude Desktop" -ForegroundColor White
Write-Host "3. Try enabling Cowork or Cowork 3P" -ForegroundColor White
Write-Host "4. If it still fails, run this script once more`n" -ForegroundColor White

Write-Host "[Common Notes]" -ForegroundColor Cyan
Write-Host "- First workspace launch may take 30 seconds to 2 minutes" -ForegroundColor Gray
Write-Host "- Restarting your PC after the fix is recommended (optional)" -ForegroundColor Gray
Write-Host "- If you need help, save the log output above`n" -ForegroundColor Gray

Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
