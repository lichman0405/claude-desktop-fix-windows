# ============================================================
# Claude Cowork 3P Brave Search MCP 初始化脚本
# 为 Claude Desktop 注册 Brave Search MCP 本地网页搜索能力
# ============================================================

Write-Host "正在为 Claude Cowork 3P 初始化 Brave Search MCP..." -ForegroundColor Cyan

# ============================================================
# 步骤 1: 检查前置依赖
# ============================================================
Write-Host "[步骤 1/4] 正在检查前置依赖..." -ForegroundColor Cyan

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$npxCommand = Get-Command npx -ErrorAction SilentlyContinue

if (-not $nodeCommand) {
    Write-Host "[错误] 未在 PATH 中找到 Node.js。" -ForegroundColor Red
    Write-Host "请先安装 Node.js 22.x 或更高版本，然后重新运行本脚本。" -ForegroundColor Yellow
    pause
    exit 1
}

if (-not $npxCommand) {
    Write-Host "[错误] 未在 PATH 中找到 npx。" -ForegroundColor Red
    Write-Host "请安装带 npm/npx 的 Node.js，然后重新运行本脚本。" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[成功] 已找到 Node.js: $($nodeCommand.Source)" -ForegroundColor Green
Write-Host "[成功] 已找到 npx: $($npxCommand.Source)" -ForegroundColor Green

# ============================================================
# 步骤 2: 输入 Brave API Key
# ============================================================
Write-Host "`n[步骤 2/4] 请输入 Brave Search API Key..." -ForegroundColor Cyan
Write-Host "可前往 https://brave.com/search/api/ 申请 API Key" -ForegroundColor Yellow

$apiKey = Read-Host "Brave Search API Key"

if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "[错误] Brave API Key 不能为空。" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[成功] 已接收 API Key" -ForegroundColor Green

# ============================================================
# 步骤 3: 加载并备份 Claude Desktop 配置
# ============================================================
Write-Host "`n[步骤 3/4] 正在加载 Claude Desktop 配置..." -ForegroundColor Cyan

$configDir = "$env:LOCALAPPDATA\Claude-3p"
$configPath = Join-Path $configDir "claude_desktop_config.json"

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "[成功] 已创建配置目录: $configDir" -ForegroundColor Green
}

if (Test-Path $configPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$configPath.$timestamp.bak"
    Copy-Item $configPath $backupPath -Force
    Write-Host "[成功] 已创建配置备份: $backupPath" -ForegroundColor Green

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "[错误] 现有配置文件不是有效的 JSON: $configPath" -ForegroundColor Red
        Write-Host "请先修复或删除该文件，然后重新运行脚本。" -ForegroundColor Yellow
        pause
        exit 1
    }
} else {
    $config = [PSCustomObject]@{}
    Write-Host "[提示] 配置文件不存在，将创建新文件。" -ForegroundColor Yellow
}

if (-not $config.PSObject.Properties['mcpServers']) {
    $config | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([PSCustomObject]@{})
}

# ============================================================
# 步骤 4: 注册 Brave Search MCP
# ============================================================
Write-Host "`n[步骤 4/4] 正在注册 Brave Search MCP..." -ForegroundColor Cyan

$serverConfig = [PSCustomObject]@{
    command = "cmd"
    args    = @(
        "/c",
        "npx",
        "-y",
        "@brave/brave-search-mcp-server",
        "--transport",
        "stdio"
    )
    env     = [PSCustomObject]@{
        BRAVE_API_KEY = $apiKey
    }
}

$hadExistingServer = [bool]$config.mcpServers.PSObject.Properties['brave-search']
$config.mcpServers | Add-Member -MemberType NoteProperty -Name "brave-search" -Value $serverConfig -Force

$config | ConvertTo-Json -Depth 20 | Out-File -FilePath $configPath -Encoding UTF8 -Force

if ($hadExistingServer) {
    Write-Host "[成功] 已更新现有 Brave Search MCP 配置" -ForegroundColor Green
} else {
    Write-Host "[成功] 已新增 Brave Search MCP 配置" -ForegroundColor Green
}

Write-Host "[成功] 配置文件已保存: $configPath" -ForegroundColor Green

# ============================================================
# 完成
# ============================================================
Write-Host ""
Write-Host "[完成] Brave Search MCP 配置已完成。" -ForegroundColor Green
Write-Host "请先重启 Claude Desktop，再测试网页搜索功能。" -ForegroundColor Yellow
Write-Host ""
Write-Host "建议测试提示词：" -ForegroundColor Cyan
Write-Host "- 搜索今天最重要的 AI 新闻" -ForegroundColor Gray
Write-Host "- 使用 brave_web_search 查找最新的 Claude Release Notes" -ForegroundColor Gray
Write-Host ""
Write-Host "注意：该方案添加的是基于 MCP 的网页搜索，不等同于 Anthropic 原生服务端 web_search 工具。" -ForegroundColor DarkGray

pause