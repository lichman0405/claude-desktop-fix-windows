# ================================================
# Claude Cowork 3P Local Skills Initialization Script
# ================================================

Write-Host "Initializing Claude Cowork 3P Local Skills..." -ForegroundColor Cyan

# ============================================================
# Step 1: Create Skills directory
# ============================================================
$skillsPath = "C:\ClaudeSkills"
if (-not (Test-Path $skillsPath)) {
    New-Item -ItemType Directory -Path $skillsPath -Force | Out-Null
    Write-Host "[OK] Directory created: $skillsPath" -ForegroundColor Green
} else {
    Write-Host "[INFO] Directory already exists: $skillsPath" -ForegroundColor Yellow
}

# ============================================================
# Step 2: Create example Skills JSON files
# ============================================================
$skills = @(
    @{
        Name    = "generate-report"
        File    = "generate-report.json"
        Content = @{
            name        = "generate-report"
            description = "Generate a structured report based on a given topic"
            parameters  = @{
                type       = "object"
                properties = @{
                    topic = @{ type = "string"; description = "The report topic" }
                }
                required   = @("topic")
            }
        }
    },
    @{
        Name    = "read-local-file"
        File    = "read-local-file.json"
        Content = @{
            name        = "read-local-file"
            description = "Read the contents of a file at the specified path"
            parameters  = @{
                type       = "object"
                properties = @{
                    filePath = @{ type = "string"; description = "Absolute path to the file" }
                }
                required   = @("filePath")
            }
        }
    },
    @{
        Name    = "summarize-data"
        File    = "summarize-data.json"
        Content = @{
            name        = "summarize-data"
            description = "Summarize and analyze the provided data"
            parameters  = @{
                type       = "object"
                properties = @{
                    data = @{ type = "string"; description = "Raw data content to summarize" }
                }
                required   = @("data")
            }
        }
    }
)

foreach ($skill in $skills) {
    $filePath = Join-Path $skillsPath $skill.File
    $skill.Content | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8 -Force
    Write-Host "[OK] Skill created: $($skill.Name)" -ForegroundColor Green
}

# ============================================================
# Step 3: Update claude_desktop_config.json
# Bug fix: use [PSCustomObject] instead of @{} so that
# Add-Member works correctly when the config file is absent.
# ============================================================
$configPath = "$env:LOCALAPPDATA\Claude-3p\claude_desktop_config.json"

if (Test-Path $configPath) {
    # ConvertFrom-Json already returns a PSCustomObject
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
} else {
    # Must be PSCustomObject, not a plain hashtable, for Add-Member to work
    $config = [PSCustomObject]@{}
}

# Add mcpServers property if missing
if (-not $config.PSObject.Properties['mcpServers']) {
    $config | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([PSCustomObject]@{})
}

# Add or update the local-skills MCP server entry
$config.mcpServers | Add-Member -MemberType NoteProperty -Name "local-skills" -Value @{
    command = "cmd"
    args    = @("/c", "echo Local Skills loaded from C:\ClaudeSkills")
} -Force

# Save config
$config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8 -Force
Write-Host "[OK] Config file updated: $configPath" -ForegroundColor Green

# ============================================================
# Done
# ============================================================
Write-Host ""
Write-Host "[Done] Initialization complete!" -ForegroundColor Green
Write-Host "Please restart Claude Desktop to activate the Skills." -ForegroundColor Yellow
Write-Host ""
Write-Host "To add new skills in the future, simply copy a .json file into C:\ClaudeSkills" -ForegroundColor Cyan

pause
