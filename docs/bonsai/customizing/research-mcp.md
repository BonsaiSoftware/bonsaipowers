# Research: MCP Integration with Claude Code and Superpowers Plugin

**Date**: April 10, 2026  
**Purpose**: Foundational research for customization guide on integrating Model Context Protocol (MCP) servers with Claude Code and Superpowers skills.

---

## Part A: MCP Support Inside the Superpowers Repo

### Summary

The superpowers repository contains **no mentions of MCP, `.mcp.json`, `mcpServers`, or the Model Context Protocol** as of the current codebase state.

### Search Results

#### 1. Grep for MCP Keywords

**Command**: Case-insensitive search across the entire repo for MCP, `.mcp.json`, `mcpServers`, and `model context protocol`.

**Results**: The grep found 7 files containing the phrase "research" in their filenames, but **no files containing MCP-related keywords**:
- `docs/bonsai/how-it-works/research-workflow.md`
- `docs/bonsai/how-it-works/research-skills.md`
- `skills/writing-skills/anthropic-best-practices.md`
- `skills/test-driven-development/testing-anti-patterns.md`
- `skills/using-superpowers/references/copilot-tools.md`
- `skills/using-superpowers/SKILL.md`
- `skills/brainstorming/SKILL.md`

**Conclusion**: The grep matched "research" in filenames, not MCP content. Zero MCP references in the codebase.

#### 2. Search in Skills Directory

**Command**: Targeted grep for `mcp__` prefix and `mcpServers` in `skills/**/*.md`

**Result**: No files found.

**Implication**: No existing skills are currently configured to use MCP tools.

#### 3. Look for `.mcp.json` Files

**Command**: Glob for `**/*.mcp.json` and `**/.mcp.json`

**Result**: No files found.

**Conclusion**: There is no `.mcp.json` shipped with the superpowers plugin.

#### 4. Commands and Agents

**Files found**:
- `/Volumes/corsair-ex/bonsai-git/bonsaipowers/commands/brainstorm.md`
- `/Volumes/corsair-ex/bonsai-git/bonsaipowers/commands/execute-plan.md`
- `/Volumes/corsair-ex/bonsai-git/bonsaipowers/commands/write-plan.md`
- `/Volumes/corsair-ex/bonsai-git/bonsaipowers/agents/code-reviewer.md`

**MCP search in these files**: Negative — no MCP references.

#### 5. JSON Configuration Files

**Grep for MCP in all `.json` files**:

Result: No MCP keywords found in any JSON files (including plugin.json, hooks.json, etc.)

#### 6. README.md Review

**File**: `/Volumes/corsair-ex/bonsai-git/bonsaipowers/README.md`

**Relevant excerpt**:
- The README mentions installation, basic workflow, skills library, and philosophy
- No section on MCP, integrations with external tools, or how to extend superpowers with MCP servers
- Mentions "Installation differs by platform" and provides instructions for Claude Code, Cursor, Codex, OpenCode, GitHub Copilot CLI, and Gemini CLI
- No guidance on combining superpowers skills with other Claude Code features like MCP

### Key Findings

1. **Zero MCP documentation in the repo**: There is no README section, how-to guide, or example skill showing MCP integration.
2. **No existing MCP skills**: None of the bundled skills reference or use MCP tools.
3. **No `.mcp.json` template**: The plugin doesn't ship a starter `.mcp.json` for users.
4. **No tool declarations in skills**: Skills are written as markdown instructions to Claude, not as declarative tool configurations.

---

## Part B: Claude Code's MCP Mechanism (From Official Documentation)

### Source Documentation

This section is drawn from the official Claude Code documentation at:
- **Main page**: https://code.claude.com/docs/en/mcp (redirected from https://docs.claude.com/en/docs/claude-code/mcp)
- **Agent SDK MCP**: https://code.claude.com/docs/en/agent-sdk/mcp.md
- **Settings**: https://code.claude.com/docs/en/settings.md
- **Skills**: https://code.claude.com/docs/en/skills.md
- **Subagents**: https://code.claude.com/docs/en/sub-agents.md

### 1. Adding an MCP Server to Claude Code

#### Three Configuration Scopes

Claude Code uses a **scope system** to determine where MCP configurations apply and who they're shared with:

| Scope    | Location                                                    | Who it affects           | Shared with team? | Purpose                                  |
|----------|-------------------------------------------------------------|--------------------------|-------------------|------------------------------------------|
| Managed  | System-level `managed-settings.json` or `managed-mcp.json`  | All users on machine     | Yes (IT-deployed) | Enterprise/organizational control        |
| User     | `~/.claude.json` (per-user, all projects)                   | Individual user globally | No                | Personal MCP servers across all projects |
| Project  | `.mcp.json` (project root, this project only)               | This project only        | Yes (in git)      | Team collaboration on shared MCPs        |
| Local    | `~/.claude.json` (per-project state)                        | This project only        | No                | Personal project-specific MCPs           |

**How scopes interact**: Project scope takes precedence over user scope. Managed settings apply globally and can restrict/allowlist what users see.

#### Discovery and Configuration Methods

**Method 1: In Code (Agent SDK)**

For programmatic use via the `@anthropic-ai/claude-agent-sdk` or `claude_agent_sdk` (Python):

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Your task",
  options: {
    mcpServers: {
      "server-name": {
        command: "npx",
        args: ["-y", "@modelcontextprotocol/server-github"],
        env: {
          GITHUB_TOKEN: process.env.GITHUB_TOKEN
        }
      }
    },
    allowedTools: ["mcp__server-name__tool-name"]
  }
})) {
  // Handle messages
}
```

**Method 2: `.mcp.json` File (Project Root)**

For Claude Code (terminal, VS Code, desktop):

Create `.mcp.json` at your project root:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/projects"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "remote-docs": {
      "type": "sse",
      "url": "https://api.example.com/mcp/sse",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    }
  }
}
```

**Note**: The `${VARIABLE_NAME}` syntax in `.mcp.json` expands environment variables at runtime.

**Method 3: `~/.claude.json` (User Scope, Persistent)**

For personal MCP servers available in all projects, edit `~/.claude.json` (not typically hand-edited; use `/config` command in Claude Code REPL instead).

---

### 2. Complete `.mcp.json` Schema

#### File Format

```json
{
  "mcpServers": {
    "<server-name>": {
      // stdio configuration
      "command": "npx",
      "args": ["@modelcontextprotocol/server-name", "arg1", "arg2"],
      "env": {
        "ENV_VAR": "value",
        "SECRET": "${SECRET_TOKEN}"
      }
      // OR http/sse configuration
      // "type": "http",
      // "url": "https://api.example.com/mcp",
      // "headers": {
      //   "Authorization": "Bearer ${TOKEN}"
      // }
    }
  }
}
```

#### Key Schema Fields

- **`mcpServers`** (object): Map of server name → configuration
  - **Server name** (string): Identifier used in tool naming (e.g., `github` becomes `mcp__github__list_issues`)
  - **Type-specific fields** (see below)

#### Transport-Specific Configuration

**Stdio Servers (Local Process)**

```json
{
  "server-name": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-name", "--arg"],
    "env": {
      "TOKEN": "${TOKEN_ENV_VAR}"
    }
  }
}
```

- **`command`**: Executable to run (e.g., `npx`, `python`, `/usr/local/bin/server`)
- **`args`**: Arguments passed to the command
- **`env`** (optional): Environment variables visible to the process. Use `${VAR_NAME}` to expand from user's environment at runtime.

**HTTP/SSE Servers (Remote)**

```json
{
  "server-name": {
    "type": "http",  // or "sse" for streaming
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}",
      "X-Custom-Header": "value"
    }
  }
}
```

- **`type`**: Either `"http"` (one-time requests) or `"sse"` (Server-Sent Events, streaming)
- **`url`**: Endpoint URL
- **`headers`** (optional): HTTP headers sent with each request

---

### 3. Tool Discovery and Naming Convention

#### Tool Naming Pattern

All MCP tools follow the pattern: **`mcp__<server-name>__<tool-name>`**

**Examples**:
- GitHub MCP server named `"github"` with tool `list_issues` → **`mcp__github__list_issues`**
- Slack server named `"slack"` with tool `send_message` → **`mcp__slack__send_message`**
- Custom database server named `"db"` with tool `query` → **`mcp__db__query`**

#### How Claude Code Discovers Tools

1. **At session start**: Claude Code connects to all configured MCP servers
2. **In system init message**: The tools available from each server are listed (visible in Agent SDK as `message.mcp_servers`)
3. **By default**: Tool definitions are **withheld from context** to save tokens (see "Tool search" below)
4. **On demand**: When Claude needs an MCP tool, the definition is loaded automatically

**Tool Search Feature** (enabled by default):

> "When you have many MCP tools configured, tool definitions can consume a significant portion of your context window. Tool search solves this by withholding tool definitions from context and loading only the ones Claude needs for each turn."

This is handled automatically—you don't configure it in `.mcp.json`.

---

### 4. Permissions and Access Control

#### In Claude Code (Terminal/IDE)

**File-based permission**: By default, all MCP servers defined in `.mcp.json` are **enabled automatically** (controlled by settings):

```json
// In ~/.claude.json (user settings, managed via /config)
{
  "enableAllProjectMcpServers": true,  // Auto-approve all .mcp.json servers
  "enabledMcpjsonServers": ["server1", "server2"],  // Approve specific servers
  "disabledMcpjsonServers": ["server3"],  // Reject specific servers
  "allowedMcpServers": [  // (Managed settings only) Whitelist of servers
    { "serverName": "github" },
    { "serverName": "slack" }
  ],
  "deniedMcpServers": [  // (Managed settings only) Blacklist of servers
    { "serverName": "filesystem" }
  ]
}
```

**Managed Settings** (for IT/admin control):

When `managed-settings.json` or `managed-mcp.json` is deployed system-wide:

- **`allowedMcpServers`**: Whitelist of MCP servers users are allowed to configure (undefined = no restrictions; empty array = complete lockdown)
- **`deniedMcpServers`**: Blacklist of servers explicitly blocked (denylist takes precedence over allowlist)
- **`allowManagedMcpServersOnly`**: If true, only managed server allowlist applies; users can still add servers, but only admin-approved ones work
- **`disabledMcpjsonServers`**: Reject specific servers from `.mcp.json` files

**Reference**: See [Managed MCP configuration](/en/mcp#managed-mcp-configuration) in official docs.

#### In Agent SDK

Use the **`allowedTools`** option to grant access:

```typescript
const options = {
  mcpServers: { /* your servers */ },
  allowedTools: [
    "mcp__github__*",        // All tools from github server
    "mcp__db__query",        // Only query tool from db server
    "mcp__slack__send_message"  // Only send_message from slack
  ]
};
```

**Best practice** (from official docs):

> "Prefer `allowedTools` over permission modes for MCP access. `permissionMode: 'acceptEdits'` does not auto-approve MCP tools (only file edits and filesystem Bash commands). `permissionMode: 'bypassPermissions'` does auto-approve MCP tools but also disables all other safety prompts, which is broader than necessary. A wildcard in `allowedTools` grants exactly the MCP server you want and nothing more."

Wildcards (`*`) allow all tools from a server without listing each individually.

---

### 5. Can Skills Invoke MCP Tools?

**Short answer**: Yes, **indirectly**. Skills don't directly declare or invoke tools. Instead, they provide **instructions to Claude**, and Claude then uses available MCP tools if they're already configured and permitted.

#### How It Works

1. **Skill = Markdown instructions** to Claude (not a tool declaration)
2. **MCP tools = Pre-configured** in `.mcp.json` or `~/.claude.json`
3. **Claude's job**: When a skill asks Claude to do something (e.g., "Query the GitHub API"), Claude checks available tools and calls the appropriate MCP tool if:
   - The tool is configured (in MCP servers)
   - The tool is permitted (in `allowedTools` or enabled via settings)
   - The task matches the tool's purpose

#### Example: Skill + MCP Integration

**Skill file** (`.claude/skills/github-issues/SKILL.md`):

```yaml
---
name: github-issues
description: Search and manage GitHub issues using the GitHub API
---

When the user asks about GitHub issues:
1. Use the GitHub API to search for issues
2. Filter by labels, assignee, or milestone
3. Report results with links to the issue tracker

Always cite the issue number and author.
```

**Configuration** (`.mcp.json`):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**What happens**:
1. User invokes `/github-issues` (or it triggers automatically)
2. Claude sees the skill instructions
3. Claude recognizes it needs to query GitHub
4. Claude checks available tools and finds `mcp__github__list_issues`, `mcp__github__search_issues`, etc.
5. Claude calls the appropriate MCP tool
6. Tool executes; Claude gets results; skill completes

#### Key Limitation

Skills **cannot** enforce tool access. A skill can say "Use the GitHub API," but if the GitHub MCP server isn't configured or is blocked by permissions, Claude will tell the user "I don't have that tool." 

To make a skill work reliably with MCP:
- Document which MCP server(s) are required
- Provide setup instructions in the skill or accompanying README
- Test that the MCP server is reachable before the skill executes (e.g., via a bash injection command)

#### Skill Frontmatter for Tool Pre-Approval

Skills can use the `allowed-tools` frontmatter field to pre-approve certain tools **while the skill is active**:

```yaml
---
name: git-automation
description: Automate git tasks
allowed-tools: Bash(git *) Read Write
---

Use git commands to:
- Stage changes
- Create commits
- Push to origin
```

However, this field currently applies to **built-in tools** (Bash, Read, Edit, WebFetch, etc.), **not MCP tools**. MCP tool access is governed by `allowedTools` in the Agent SDK or settings in Claude Code.

---

### 6. Transport Types: stdio, SSE, and HTTP

#### stdio (Local Process)

**Use when**: You have a command to run (e.g., `npx @modelcontextprotocol/server-name`)

**Configuration**:
```json
{
  "server-name": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

**Advantages**:
- Local execution—no network latency
- Direct access to local files and environment
- No external dependencies

**Disadvantages**:
- Server must be installable on the user's machine
- Requires Node.js, Python, or appropriate runtime

#### HTTP (Stateless Requests)

**Use when**: You have a URL and don't need streaming responses

**Configuration**:
```json
{
  "server-name": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

**Advantages**:
- Cloud-hosted, no local installation
- Works from any machine
- Clean separation of concerns

**Disadvantages**:
- Network latency and potential timeouts
- Requires server to support HTTP transport

#### SSE (Server-Sent Events / Streaming)

**Use when**: You want long-lived, streaming connections

**Configuration**:
```json
{
  "server-name": {
    "type": "sse",
    "url": "https://api.example.com/mcp/sse",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

**Advantages**:
- Persistent connection—lower overhead for repeated calls
- Real-time streaming of results
- Better for large data transfers

**Disadvantages**:
- Requires server-side support for SSE
- May block on stuck connections (though SDK has 60-second timeout)

#### Default Timeout

The MCP SDK has a **default timeout of 60 seconds** for server connections. If your server takes longer to start, the connection will fail.

---

### 7. MCP + Subagents

#### Can Subagents Use MCP Tools?

**In Claude Code (REPL)**: Yes, but indirectly. When you spawn a subagent via a skill with `context: fork`, the subagent **inherits the parent session's MCP servers** and permissions.

**In Agent SDK**: Use the `mcpServers` option when creating a subagent context. Subagents spawned via `query()` can have independent MCP configurations.

#### Example: Forked Skill with MCP

**Skill** (`.claude/skills/research/SKILL.md`):

```yaml
---
name: research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS using available tools:
1. Search documentation
2. Query databases
3. Fetch API data
4. Summarize findings
```

**How it works**:
1. User invokes `/research "authentication patterns"`
2. Claude spawns an `Explore` subagent with the skill as the prompt
3. The subagent inherits MCP servers from parent (e.g., GitHub API, Slack, databases)
4. Subagent works independently, returns summary to main session

#### Permissions and Subagents

**Current state**: There is **no per-subagent MCP allow/deny mechanism**. All subagents spawned from a parent session have the same MCP tool access as the parent.

To restrict a subagent's tool access:
- Use `allowed-tools` in the subagent's markdown definition (for built-in tools)
- In Agent SDK, pass a custom `allowedTools` list when creating the subagent

There is **no built-in way to restrict MCP access per subagent**—you must rely on the parent session's global settings.

---

### 8. Best Practices for MCP Configuration

#### Settings File Hierarchy

**Where to place MCP configuration**:

| Scenario                                  | Location                       | Scope      | Notes                                  |
|-------------------------------------------|--------------------------------|------------|----------------------------------------|
| Shared across all projects (personal)     | `~/.claude.json`               | User       | Edited via `/config` command           |
| Shared with team on this project          | `.mcp.json` (root)             | Project    | Commit to git for team sharing         |
| Project-specific but secret               | `.mcp.json` + env vars         | Project    | Secrets in `.env`, referenced as `${VAR}` |
| Enterprise-wide (IT-managed)              | `managed-mcp.json` (system)    | Managed    | Deployed by IT, read-only for users    |
| Local & secret (this machine only)        | `~/.claude.json`               | Local      | Not shared; env vars recommended       |

#### Configuration Best Practices

**1. Use Environment Variables for Secrets**

**Good** (`.mcp.json`):
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

The `${GITHUB_TOKEN}` expands from your shell environment at runtime.

**Bad**: Hardcoding tokens in `.mcp.json`.

**2. Document Required Environment Variables**

Create a `.env.example` at project root:

```bash
# Required MCP environment variables
GITHUB_TOKEN=ghp_xxxx...  # GitHub personal access token (https://github.com/settings/tokens)
DATABASE_URL=postgres://...  # Postgres connection string for DB MCP server
SLACK_TOKEN=xoxb-...  # Slack bot token
```

Instruct team members to `cp .env.example .env` and fill in their secrets.

**3. Separate Public Config from Secret Config**

**Commit to git** (`.mcp.json`):
- Server names and URLs
- Command and args (if public)
- Non-secret headers or config

**Don't commit** (`.env`, `~/.claude.json`):
- API keys, tokens, passwords
- Database credentials
- User-specific settings

**4. Version `.mcp.json` as Team Config**

If your team shares MCP servers (e.g., internal documentation server, shared database):
- Commit `.mcp.json` to the repo
- Reference secrets via `${VAR_NAME}` syntax
- Document required env vars in README or CONTRIBUTING.md

**5. Use Project Scope for Team Servers**

Add `.mcp.json` to your project root, not `~/.claude.json`:
- **Advantage**: Team members pull the latest config via git
- **Advantage**: Different projects can have different servers
- **Advantage**: Easy onboarding (no manual setup)

Use user scope (`~/.claude.json`) only for personal servers (e.g., your personal Notion workspace, your GitHub account).

#### Settings File Locations (Reference)

**Claude Code (Terminal/IDE)**:
- **User settings**: `~/.claude.json` (contains OAuth tokens, preferences, user-scope MCP servers)
- **Project MCP**: `.mcp.json` (project root, committed to git)
- **Local state**: `.claude/state.json` (machine-specific, not committed)
- **Managed (IT)**: `/etc/claude/managed-settings.json` (Linux/macOS) or `HKLM:\Software\Anthropic\Claude` (Windows)

**Agent SDK**:
- **Programmatic**: Pass `mcpServers` to `options` in `query()` call
- **File-based**: Create `.mcp.json` in project root; set `settingSources: ["project"]` to load it

#### Permission Settings in `~/.claude.json`

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["github", "slack"],
  "disabledMcpjsonServers": ["filesystem"],
  "allowedMcpServers": [
    { "serverName": "github" },
    { "serverName": "slack" }
  ],
  "deniedMcpServers": [
    { "serverName": "filesystem" }
  ]
}
```

**Note**: Most users don't edit `~/.claude.json` directly. Use `/config` in the Claude Code REPL to adjust these settings visually.

---

### 9. Caveats and Known Limitations

#### MCP + Plugins

MCP servers configured in `.mcp.json` are **available to all plugins** running in the same Claude Code session. There is no way to restrict which plugins can access which MCP servers.

#### MCP + Managed Settings

When `managed-mcp.json` is deployed:
- **`allowedMcpServers`** whitelists which servers are allowed
- **`deniedMcpServers`** blacklists specific servers (takes precedence)
- Users can still add their own servers to `~/.claude.json` or `.mcp.json`, but only approved servers will connect

#### Tool Timeout

MCP tool calls have a default timeout of 60 seconds. Long-running operations (e.g., large database queries) may fail.

#### Context Window Impact

By default, tool definitions are withheld (tool search enabled) to save context. However, if you have **hundreds of MCP tools**, searching for the right tool on each turn may slow down responses slightly.

#### No Rollback on Permissions

If you deny an MCP server but a skill or CLAUDE.md file expects it, Claude will tell the user "tool not available" rather than gracefully degrading. Document which MCP servers are required for each skill.

---

## Summary Table: MCP Configuration at a Glance

| Question                              | Answer                                                                    |
|---------------------------------------|---------------------------------------------------------------------------|
| **How to add MCP server?**            | Create `.mcp.json` at project root or edit `~/.claude.json` via `/config` |
| **What's the `.mcp.json` format?**    | See schema above (stdio, HTTP, SSE configs)                              |
| **Tool naming convention?**           | `mcp__<server-name>__<tool-name>`                                        |
| **How to grant tool access?**         | `enabledMcpjsonServers` in settings or `allowedTools` in Agent SDK       |
| **Can skills use MCP?**              | Yes—indirectly. Skill instructions guide Claude; Claude uses MCP tools if available |
| **stdio vs HTTP vs SSE?**            | stdio = local process; HTTP = stateless remote; SSE = streaming remote   |
| **Do subagents get MCP access?**     | Yes, they inherit parent session's servers; no per-subagent restrictions  |
| **Where do secrets go?**             | `~/.env` or `~/.zshenv`; reference as `${VAR}` in `.mcp.json`            |
| **Commit `.mcp.json` to git?**       | Yes, if it's team-shared config; keep secrets in env vars               |

---

## Appendix: Official Documentation Links

- **Main MCP Page**: https://code.claude.com/docs/en/mcp
- **Agent SDK MCP**: https://code.claude.com/docs/en/agent-sdk/mcp.md
- **Settings Reference**: https://code.claude.com/docs/en/settings.md
- **Skills Guide**: https://code.claude.com/docs/en/skills.md
- **Subagents**: https://code.claude.com/docs/en/sub-agents.md
- **MCP Server Directory**: https://github.com/modelcontextprotocol/servers
- **MCP Specification**: https://modelcontextprotocol.io/

