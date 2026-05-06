# Claude Desktop Third-Party Tools

Utility scripts for fixing and extending Claude Desktop's Cowork 3P workspace on Windows.

## Language Versions

| Folder | Language | Contents |
|---|---|---|
| [`en/`](en/) | English | Fix scripts, Skills init scripts, Brave Search MCP init script, full README |
| [`zh/`](zh/) | Chinese | Fix scripts, Skills init scripts, Brave Search MCP init script, full README |

## Quick Start

**To fix a broken Cowork 3P workspace:**
- **English (easiest):** double-click [`en/cowork-3p-fix.bat`](en/cowork-3p-fix.bat)
- **English (PowerShell):** run [`en/cowork-3p-fix.ps1`](en/cowork-3p-fix.ps1) as Administrator
- **Chinese (easiest):** double-click [`zh/cowork-3p-fix.bat`](zh/cowork-3p-fix.bat)
- **Chinese (PowerShell):** run [`zh/cowork-3p-fix.ps1`](zh/cowork-3p-fix.ps1) as Administrator

**To initialize local Skills:**
- **English:** run [`en/claude_skills_init.ps1`](en/claude_skills_init.ps1) or double-click [`en/claude_skills_init.bat`](en/claude_skills_init.bat)
- **Chinese:** run [`zh/claude_skills_init.ps1`](zh/claude_skills_init.ps1) or double-click [`zh/claude_skills_init.bat`](zh/claude_skills_init.bat)

**To add web search to Cowork 3P:**
- **English:** run [`en/brave-search-mcp-init.ps1`](en/brave-search-mcp-init.ps1)
- **Chinese:** run [`zh/brave-search-mcp-init.ps1`](zh/brave-search-mcp-init.ps1)
- **Requirements:** Node.js with `npx` available in `PATH`, plus a Brave Search API key
- **Important:** This adds MCP-based web search through Brave. It does not restore Anthropic's native server-side `web_search` tool.

See the README in each folder for full details.

## Detailed 3P Setup (Windows)

This section covers the parts that usually cause the most confusion in a Cowork 3P deployment:

1. how to turn on Developer mode
2. how to fill in the third-party provider settings
3. how to configure `coworkEgressAllowedHosts`

The instructions below are based on Anthropic's public Cowork on 3P documentation and support articles.

### 1. Turn on Developer mode

Open Claude Desktop. You do not need to log in first.

Use this menu path:

```text
Help -> Troubleshooting -> Enable Developer mode
```

After Developer mode is enabled, open the 3P setup window here:

```text
Developer -> Configure third-party inference
```

This is the easiest and safest way to build a working configuration because the setup UI validates values and can export a Windows `.reg` file.

### 2. Understand where the 3P configuration is stored

Cowork on 3P uses two configuration layers on Windows:

- **Managed policy:** `HKCU\SOFTWARE\Policies\Claude` or `HKLM\SOFTWARE\Policies\Claude`
- **Local setup UI output:** `%LOCALAPPDATA%\Claude-3p\configLibrary\`

Important behavior:

- The setup UI writes into the local `configLibrary` directory.
- Managed registry policy wins over local config when both are present.
- Configuration is read once at app launch, so you must fully quit and reopen Claude Desktop after any change.
- All values in the Windows policy store are written as **strings**, even booleans and arrays.

That last point matters a lot: keys such as `inferenceModels` and `coworkEgressAllowedHosts` must be written as **JSON strings**, not as native registry arrays.

### 3. Fill in the 3P provider settings

In the setup UI, the provider-related fields are under the **Connection** section.

The main activation key is:

- `inferenceProvider`

Supported values are:

- `gateway`
- `vertex`
- `bedrock`
- `foundry`

Cowork 3P only switches into third-party mode when `inferenceProvider` is set and the required credential keys for that provider are also present and valid.

#### Recommended path: use the setup UI

Open:

```text
Developer -> Configure third-party inference
```

Then fill the provider fields shown in the UI and export the result as a `.reg` file.

#### Gateway example

For most custom or proxy-based setups, the easiest provider is `gateway`.

Required gateway keys:

- `inferenceProvider` = `gateway`
- `inferenceGatewayBaseUrl` = your gateway base URL
- `inferenceGatewayApiKey` = your gateway credential

Optional but commonly useful:

- `inferenceGatewayAuthScheme` = `auto`, `bearer`, or `x-api-key`
- `inferenceGatewayHeaders` = JSON array of extra headers such as `"Header-Name: Value"`
- `deploymentOrganizationUuid` = strongly recommended for support and telemetry separation
- `disableDeploymentModeChooser` = `true` if you want the app to boot directly into 3P mode

Your gateway must expose `/v1/messages`. Anthropic's public support article also notes that LLM gateways should forward the `anthropic-beta` and `anthropic-version` headers.

Example `.reg` values for a gateway deployment:

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\SOFTWARE\Policies\Claude]
"inferenceProvider"="gateway"
"inferenceGatewayBaseUrl"="https://your-gateway.example.com/v1"
"inferenceGatewayApiKey"="YOUR_GATEWAY_API_KEY"
"inferenceGatewayAuthScheme"="bearer"
"deploymentOrganizationUuid"="11111111-2222-3333-4444-555555555555"
"disableDeploymentModeChooser"="true"
```

#### Other providers

If you are not using a gateway, use the provider-specific keys instead:

- **Vertex AI:** `inferenceProvider=vertex`, plus project, region, and credentials file or OAuth settings
- **Bedrock:** `inferenceProvider=bedrock`, plus region and bearer token or AWS profile-based credentials
- **Azure AI Foundry:** `inferenceProvider=foundry`, plus resource name and API key

If you want to create the config manually instead of using the setup UI, Anthropic's configuration reference is the authoritative source for the full key list and required fields.

### 4. Configure allowed egress hosts

The key for this is:

- `coworkEgressAllowedHosts`

Type:

- JSON array encoded as a **single string**

What it controls:

- the Cowork tab sandbox's outbound access for web fetches, shell commands, and package installs

What it does **not** control:

- the Code tab, which runs on the host with the user's normal network access

Important behavior from Anthropic's documentation:

- when `coworkEgressAllowedHosts` is **unset**, only the inference endpoint is reachable from the Cowork sandbox
- when it is unset, package installs and web fetches generally fail with HTTP 403
- the configured inference endpoint is always implicitly allowed
- `"[\"*\"]"` disables egress filtering
- wildcard hostnames such as `*.example.com` are supported

#### UI path

In the setup UI, this setting appears under:

```text
Developer -> Configure third-party inference -> Sandbox & workspace
```

#### Correct Windows registry format

This is the most important formatting rule:

- **Correct:** the registry value is one string containing JSON
- **Wrong:** trying to create a native Windows registry array

Example:

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\SOFTWARE\Policies\Claude]
"coworkEgressAllowedHosts"="[\"pypi.org\",\"*.pypi.org\",\"registry.npmjs.org\",\"github.com\",\"api.github.com\",\"*.githubusercontent.com\"]"
```

#### Practical host lists

Minimal Python and npm-friendly allowlist:

```json
["pypi.org", "*.pypi.org", "registry.npmjs.org"]
```

Development-friendly allowlist for common open-source workflows:

```json
[
	"pypi.org",
	"*.pypi.org",
	"registry.npmjs.org",
	"github.com",
	"api.github.com",
	"*.githubusercontent.com"
]
```

Disable egress filtering entirely:

```json
["*"]
```

#### Scope warning

`coworkEgressAllowedHosts` only governs the Cowork tab sandbox. If you want to prevent unrestricted host-network access from the Code tab, you must separately disable the Code tab:

```reg
"isClaudeCodeForDesktopEnabled"="false"
```

### 5. Recommended verification flow

After you change the provider or egress settings:

1. fully quit Claude Desktop
2. reopen it
3. confirm the app enters 3P mode rather than standard mode
4. test a Cowork action that needs outbound access, such as package installation or web fetching

Expected behavior when 3P mode is configured correctly:

- Cowork should use your selected inference provider
- package installs and web fetches should work only for the hosts you allowed
- if `coworkEgressAllowedHosts` is too narrow, Cowork sandbox actions fail while the inference path still works

### 6. Official references

- Installation and setup: https://support.claude.com/en/articles/14680741-install-and-configure-claude-cowork-with-third-party-platforms
- Configuration reference: https://claude.com/docs/cowork/3p/configuration
- Cowork on 3P overview: https://support.claude.com/en/articles/14680729-use-claude-cowork-with-third-party-platforms
