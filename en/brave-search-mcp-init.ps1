# ============================================================
# Claude Cowork 3P Brave Search MCP Initialization Script
# Registers Brave Search MCP for local web search in Claude Desktop
# ============================================================

Write-Host "Initializing Brave Search MCP for Claude Cowork 3P..." -ForegroundColor Cyan

# ============================================================
# Step 1: Verify prerequisites
# ============================================================
Write-Host "[Step 1/4] Checking prerequisites..." -ForegroundColor Cyan

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$npxCommand = Get-Command npx -ErrorAction SilentlyContinue

if (-not $nodeCommand) {
    Write-Host "[ERROR] Node.js was not found in PATH." -ForegroundColor Red
    Write-Host "Install Node.js 22.x or later, then re-run this script." -ForegroundColor Yellow
    pause
    exit 1
}

if (-not $npxCommand) {
    Write-Host "[ERROR] npx was not found in PATH." -ForegroundColor Red
    Write-Host "Install Node.js with npm/npx support, then re-run this script." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[OK] Node.js found: $($nodeCommand.Source)" -ForegroundColor Green
Write-Host "[OK] npx found: $($npxCommand.Source)" -ForegroundColor Green

# ============================================================
# Step 2: Prompt for Brave API key
# ============================================================
Write-Host "`n[Step 2/4] Enter Brave Search API key..." -ForegroundColor Cyan
Write-Host "Get a key from https://brave.com/search/api/" -ForegroundColor Yellow

$apiKey = Read-Host "Brave Search API Key"

if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "[ERROR] Brave API key cannot be empty." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[OK] API key received" -ForegroundColor Green

# ============================================================
# Step 3: Load and back up Claude Desktop config
# ============================================================
Write-Host "`n[Step 3/4] Loading Claude Desktop config..." -ForegroundColor Cyan

$configDir = "$env:LOCALAPPDATA\Claude-3p"
$configPath = Join-Path $configDir "claude_desktop_config.json"

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "[OK] Created config directory: $configDir" -ForegroundColor Green
}

if (Test-Path $configPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$configPath.$timestamp.bak"
    Copy-Item $configPath $backupPath -Force
    Write-Host "[OK] Config backup created: $backupPath" -ForegroundColor Green

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "[ERROR] Existing config is not valid JSON: $configPath" -ForegroundColor Red
        Write-Host "Fix or remove the file, then run the script again." -ForegroundColor Yellow
        pause
        exit 1
    }
} else {
    $config = [PSCustomObject]@{}
    Write-Host "[INFO] Config file does not exist yet. A new one will be created." -ForegroundColor Yellow
}

if (-not $config.PSObject.Properties['mcpServers']) {
    $config | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([PSCustomObject]@{})
}

# ============================================================
# Step 4: Register Brave Search MCP
# ============================================================
Write-Host "`n[Step 4/4] Registering Brave Search MCP..." -ForegroundColor Cyan

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
    Write-Host "[OK] Updated existing Brave Search MCP entry" -ForegroundColor Green
} else {
    Write-Host "[OK] Added new Brave Search MCP entry" -ForegroundColor Green
}

Write-Host "[OK] Config file saved: $configPath" -ForegroundColor Green

# ============================================================
# Done
# ============================================================
Write-Host "" 
Write-Host "[Done] Brave Search MCP setup is complete." -ForegroundColor Green
Write-Host "Restart Claude Desktop before testing web search." -ForegroundColor Yellow
Write-Host "" 
Write-Host "Suggested test prompts:" -ForegroundColor Cyan
Write-Host "- Search the web for today's top AI news" -ForegroundColor Gray
Write-Host "- Use brave_web_search to find the latest Claude release notes" -ForegroundColor Gray
Write-Host "" 
Write-Host "Note: This adds MCP-based web search. It does not restore Anthropic's native server-side web_search tool." -ForegroundColor DarkGray

pause