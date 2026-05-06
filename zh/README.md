# Claude Desktop 第三方工具（中文版）

适用于 Windows 的 Claude Desktop Cowork 3P 工作区修复与扩展工具集。

---

## 文件说明

| 文件 | 类型 | 用途 |
|---|---|---|
| `cowork-3p-fix.ps1` | PowerShell | 修复 Cowork 3P 工作区启动失败 |
| `cowork-3p-fix.bat` | 批处理 | 直接启动修复脚本，并自动请求管理员权限 |
| `claude_skills_init.ps1` | PowerShell | 初始化本地 Skills 并更新 Claude Desktop 配置 |
| `claude_skills_init.bat` | 批处理 | 直接启动 Skills 初始化脚本 |
| `brave-search-mcp-init.ps1` | PowerShell | 注册 Brave Search MCP，为 Cowork 3P 增加网页搜索能力 |

---

## Cowork 3P 工作区启动修复

**适用场景：** Claude Desktop 的 Cowork 或 Cowork 3P 工作区无法启动时使用。

### 修复步骤（脚本自动完成）

1. 验证管理员权限
2. 终止 Claude Desktop 及 `cowork-svc` 相关进程
3. 删除 `%LOCALAPPDATA%\Claude-3p` 下的旧虚拟机缓存目录
4. 自动检测 Claude Desktop UWP 包标识符，并将真实 VM bundle 文件硬链接到包的 LocalCache 路径
5. 重启 `CoworkVMService` Windows 服务

### 运行方式

**方式 A — 批处理：**
```
cowork-3p-fix.bat
```

**方式 B — PowerShell：**
```powershell
.\cowork-3p-fix.ps1
```

以上方式都应以管理员身份运行。

### 修复后操作

1. 关闭终端窗口
2. 重新打开 Claude Desktop
3. 尝试开启 Cowork 或 Cowork 3P
4. 如仍失败，再运行一次脚本

---

## 本地 Skills 初始化

**适用场景：** 需要在本地创建 Claude Skills 并注册到 `claude_desktop_config.json` 时使用。

### 脚本功能

1. 创建 `C:\ClaudeSkills` 目录
2. 写入示例 Skill JSON 文件
3. 创建或更新 `%LOCALAPPDATA%\Claude-3p\claude_desktop_config.json` 中的 `local-skills` MCP 配置

### 运行方式

**方式 A — 批处理：**
```
claude_skills_init.bat
```

**方式 B — PowerShell：**
```powershell
.\claude_skills_init.ps1
```

脚本执行完成后，重启 Claude Desktop 即可激活 Skills。

---

## 为 Cowork 3P 增加网页搜索

**适用场景：** 希望让 Cowork 3P 中的 Claude 具备当前网页搜索能力时使用。

### 为什么没有原生 web search

Anthropic 官方把 `web_search` 定义为 Claude API 的服务端工具，并且需要在 Claude Console 中启用。Cowork 3P 是本地桌面式运行环境，因此不会自动继承这项原生服务端能力。

### 推荐方案

使用 Brave Search MCP。它可以通过 MCP 为 Claude 提供网页搜索能力，是当前在 Cowork 3P 里最实用的替代方案。

### 脚本会做什么

1. 检查 `node` 和 `npx` 是否可用
2. 提示输入 Brave Search API Key
3. 备份 `%LOCALAPPDATA%\Claude-3p\claude_desktop_config.json`
4. 新增或更新 `brave-search` MCP 配置，实际启动命令为：

```text
cmd /c npx -y @brave/brave-search-mcp-server --transport stdio
```

### 运行前提

- 已安装 Claude Desktop
- 系统已安装 Node.js，且 `npx` 在 `PATH` 中可用
- 已申请 Brave Search API Key：`https://brave.com/search/api/`

### 运行方式

```powershell
.\brave-search-mcp-init.ps1
```

脚本执行完成后，请重启 Claude Desktop，再测试网页搜索。

### 注意事项

- 这是基于 MCP 的网页搜索补方案，不等同于 Anthropic 原生 `web_search` 工具
- Brave Search MCP 使用的是 Brave 自己的 API 配额、限制和计费
- 工具名称、行为和 Anthropic 原生 web search 不完全一致
