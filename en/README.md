# Claude Desktop Third-Party Tools

English-language utility scripts for fixing and extending Claude Desktop's Cowork 3P workspace on Windows.

---

## Files

| File | Type | Purpose |
|---|---|---|
| `cowork-3p-fix.ps1` | PowerShell | Fix Cowork 3P workspace launch failures |
| `cowork-3p-fix.bat` | Batch | Launch the Cowork 3P fix script with administrator elevation |
| `claude_skills_init.ps1` | PowerShell | Initialize local Skills and update Claude Desktop config |
| `claude_skills_init.bat` | Batch | Launch the local Skills initialization script |
| `brave-search-mcp-init.ps1` | PowerShell | Register Brave Search MCP to add web search to Cowork 3P |

---

## Cowork 3P Workspace Launch Fix

**Use when:** Claude Desktop's Cowork or Cowork 3P workspace fails to start.

### What it does

1. Verifies the script is running as Administrator.
2. Kills Claude Desktop and `cowork-svc` related processes.
3. Deletes stale VM cache directories under `%LOCALAPPDATA%\Claude-3p`.
4. Auto-detects the Claude Desktop UWP package identifier and creates hard links from the real VM bundle files into the package `LocalCache` path.
5. Restarts the `CoworkVMService` Windows service.

### Requirements

- Windows 10/11
- Claude Desktop installed
- VM bundle files already downloaded by Claude Desktop

### How to run

**Option A — Batch file:**
```
cowork-3p-fix.bat
```

**Option B — PowerShell:**
```powershell
.\cowork-3p-fix.ps1
```

Run either option as Administrator.

### After running

1. Close the terminal window.
2. Reopen Claude Desktop.
3. Try enabling Cowork or Cowork 3P.
4. If it still fails, run the script again.

---

## Local Skills Initialization

**Use when:** You want to set up local Claude Skills and register them in `claude_desktop_config.json`.

### What it does

1. Creates `C:\ClaudeSkills`.
2. Writes three example skill definition JSON files.
3. Creates or updates `%LOCALAPPDATA%\Claude-3p\claude_desktop_config.json` with a `local-skills` MCP entry.

### How to run

**Option A — Batch file:**
```
claude_skills_init.bat
```

**Option B — PowerShell:**
```powershell
.\claude_skills_init.ps1
```

Restart Claude Desktop after the script completes.

### Implementation note

This script uses `PSCustomObject` when it needs to create a new config object, avoiding the plain-hashtable `Add-Member` bug that can break `mcpServers` updates.

---

## Web Search for Cowork 3P

**Use when:** You want Claude in Cowork 3P to access current web results.

### Why native web search is missing

Anthropic documents `web_search` as a server-side Claude API tool that must be enabled in Claude Console. Cowork 3P is a local desktop-style environment, so it does not automatically inherit that native server-side tool.

### Recommended workaround

Use Brave Search MCP. This gives Claude an MCP-based web search path through Brave Search, which is the closest practical replacement for current web lookup in Cowork 3P.

### What the script does

1. Verifies `node` and `npx` are available.
2. Prompts for your Brave Search API key.
3. Backs up `%LOCALAPPDATA%\Claude-3p\claude_desktop_config.json`.
4. Creates or updates a `brave-search` MCP entry that launches:

```text
cmd /c npx -y @brave/brave-search-mcp-server --transport stdio
```

### Requirements

- Node.js with `npx` available in `PATH`
- Brave Search API key from `https://brave.com/search/api/`
- Claude Desktop installed

### How to run

```powershell
.\brave-search-mcp-init.ps1
```

Restart Claude Desktop after the script completes.

### Important caveats

- This is an MCP-based workaround, not Anthropic's native `web_search` tool.
- Brave Search MCP uses separate Brave API access, limits, and billing.
- Tool names and behavior differ from Anthropic's built-in server-side web search.
