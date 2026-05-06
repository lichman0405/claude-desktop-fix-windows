# ================================================
# Claude Cowork 3P 本地 Skills 一键初始化脚本
# ================================================

Write-Host "正在初始化 Claude Cowork 3P 本地 Skills..." -ForegroundColor Cyan

# 1. 创建 Skills 目录
$skillsPath = "C:\ClaudeSkills"
if (-not (Test-Path $skillsPath)) {
    New-Item -ItemType Directory -Path $skillsPath -Force | Out-Null
    Write-Host "✅ 已创建目录: $skillsPath" -ForegroundColor Green
} else {
    Write-Host "ℹ️ 目录已存在: $skillsPath" -ForegroundColor Yellow
}

# 2. 创建示例 Skills
$skills = @(
    @{
        Name = "生成报告"
        File = "生成报告.json"
        Content = @{
            name = "生成报告"
            description = "根据主题生成结构化报告"
            parameters = @{
                type = "object"
                properties = @{
                    主题 = @{ type = "string" }
                }
                required = @("主题")
            }
        }
    },
    @{
        Name = "读取本地文件"
        File = "读取本地文件.json"
        Content = @{
            name = "读取本地文件"
            description = "读取指定路径的文件内容"
            parameters = @{
                type = "object"
                properties = @{
                    文件路径 = @{ type = "string" }
                }
                required = @("文件路径")
            }
        }
    },
    @{
        Name = "简单数据总结"
        File = "简单数据总结.json"
        Content = @{
            name = "简单数据总结"
            description = "对提供的数据进行总结分析"
            parameters = @{
                type = "object"
                properties = @{
                    数据内容 = @{ type = "string" }
                }
                required = @("数据内容")
            }
        }
    }
)

foreach ($skill in $skills) {
    $filePath = Join-Path $skillsPath $skill.File
    $skill.Content | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8 -Force
    Write-Host "✅ 已创建技能: $($skill.Name)" -ForegroundColor Green
}

# 3. 修改 claude_desktop_config.json
$configPath = "$env:LOCALAPPDATA\Claude-3p\claude_desktop_config.json"

# 读取现有配置（如果存在）
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
} else {
    $config = @{}
}

# 添加或更新 MCP 配置
if (-not $config.mcpServers) {
    $config | Add-Member -MemberType NoteProperty -Name mcpServers -Value @{}
}

$config.mcpServers | Add-Member -MemberType NoteProperty -Name "local-skills" -Value @{
    command = "cmd"
    args = @("/c", "echo Local Skills loaded from C:\ClaudeSkills")
} -Force

# 保存配置
$config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8 -Force
Write-Host "✅ 已更新配置文件: $configPath" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 初始化完成！" -ForegroundColor Green
Write-Host "请重启 Claude Desktop 后测试 Skills 功能。" -ForegroundColor Yellow
Write-Host ""
Write-Host "以后添加新技能只需把 .json 文件复制到 C:\ClaudeSkills 文件夹即可。" -ForegroundColor Cyan

pause