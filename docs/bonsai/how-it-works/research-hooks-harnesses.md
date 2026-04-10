# Superpowers Plugin System: Hooks and Multi-Harness Architecture

**Research Date:** 2026-04-10  
**Repository:** /Volumes/corsair-ex/bonsai-git/bonsaipowers/  
**Scope:** Complete investigation of SessionStart hook mechanism, context injection, and multi-harness support

---

## Executive Summary

The superpowers plugin system uses a **polyglot hook wrapper** to inject the "using-superpowers" skill content into Claude Code sessions at startup. This context establishes skill-usage discipline before the user's first message. The system supports **six distinct harnesses** (Claude Code, Cursor, Copilot CLI, Codex, Gemini CLI, and OpenCode), each with different tool-name mappings and context-injection strategies. This document provides exhaustive coverage of how hooks fire, content flows through the system, and how each harness receives superpowers awareness.

---

## Part 1: The Hook System

### 1.1 Hook Registration Files

#### hooks.json (Claude Code)
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/hooks/hooks.json`  
**Lines:** 1-16

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**Key Points:**
- Hook Type: `SessionStart` — fires when Claude Code starts a new session
- Matcher: `startup|clear|compact` — triggers on these session events
- Command: Points to `run-hook.cmd` with argument `session-start` (no file extension)
- Async: `false` — blocks session start until hook completes

#### hooks-cursor.json (Cursor IDE)
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/hooks/hooks-cursor.json`  
**Lines:** 1-10

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "./hooks/session-start"
      }
    ]
  }
}
```

**Key Points:**
- Hook Type: `sessionStart` (camelCase, platform convention)
- Command: Direct path to extensionless bash script
- Context: Referenced in `.cursor-plugin/plugin.json` at line 24

---

### 1.2 The Polyglot Hook Wrapper

#### run-hook.cmd (Cross-Platform Bridge)
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/hooks/run-hook.cmd`  
**Lines:** 1-47

The file is valid syntax in both CMD.exe (Windows) and bash (Unix).

**On Windows (CMD.exe):**
1. `: << 'CMDBLOCK'` — interpreted as label, ignores heredoc delimiter
2. Batch code executes, searching for bash.exe in standard Git locations
3. Falls back to PATH if not found
4. Calls bash with the script name and arguments
5. `exit /b` stops execution before reaching Unix code
6. If no bash found, exits silently (graceful degradation)

**On Unix/macOS/Linux:**
1. `: << 'CMDBLOCK'` — `:` is no-op, `<<` starts heredoc that consumes all CMD code
2. Bash interpreter skips everything until `CMDBLOCK` marker
3. Remaining bash code executes directly
4. Script runs without wrapping

**Windows Support Fallback Chain:**
- `C:\Program Files\Git\bin\bash.exe` (default Git for Windows)
- `C:\Program Files (x86)\Git\bin\bash.exe` (32-bit Git)
- `bash` on PATH (user-installed Git Bash, MSYS2, Cygwin)
- Silent exit if no bash (graceful degradation)

---

### 1.3 The SessionStart Script

#### session-start (Main Hook Logic)
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/hooks/session-start`  
**Type:** Bourne-Again shell script (extensionless)

**Step-by-Step Execution:**

1. **Environment Detection (lines 8-9)**
   - `SCRIPT_DIR`: Set to hook script's directory
   - `PLUGIN_ROOT`: Resolves to parent directory

2. **Legacy Migration Warning (lines 11-15)**
   - Checks if old `~/.config/superpowers/skills` exists
   - Builds a deprecation message if found

3. **Skill Content Loading (lines 17-18)**
   - Reads the entire `using-superpowers/SKILL.md` file
   - Falls back to error message if file not readable

4. **JSON Escaping (lines 20-31)**
   - Pure bash character replacement (no sed/awk for Windows compat)
   - Escapes: backslash, quotes, newlines, carriage returns, tabs
   - Uses bash parameter substitution `${var//old/new}`

5. **Context Assembly (lines 33-35)**
   - Wraps escaped skill content in `<EXTREMELY_IMPORTANT>` tags
   - Adds warning message if legacy skills detected

6. **Platform Detection & JSON Output (lines 37-55)**
   
   **Cursor IDE:**
   ```json
   {
     "additional_context": "..."
   }
   ```
   
   **Claude Code:**
   ```json
   {
     "hookSpecificOutput": {
       "hookEventName": "SessionStart",
       "additionalContext": "..."
     }
   }
   ```
   
   **Copilot CLI & Others (SDK Standard):**
   ```json
   {
     "additionalContext": "..."
   }
   ```

7. **Exit (line 57)**
   - Returns success code
   - Hook system processes JSON output and injects context

---

## Part 2: Context Injection Strategy

### 2.1 What Gets Injected

**Content:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/using-superpowers/SKILL.md`  
**Size:** Approximately 350 lines

**What's Included:**
- YAML frontmatter with skill metadata
- `<SUBAGENT-STOP>` section
- `<EXTREMELY-IMPORTANT>` instructions about skill usage discipline
- Red Flags table (rationalizations to avoid)
- Instruction Priority guide
- How to Access Skills section
- Using Skills section with flowchart
- Skill Priority guidelines
- Skill Types classification

**Core Instruction:**
```
If you think there is even a 1% chance a skill might apply to what you are doing, 
you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. 
YOU MUST USE IT.
```

---

### 2.2 When Content Is Injected

**Timing:** SessionStart hook fires synchronously before user interaction

**Sequence:**
1. User starts Claude Code session in a project with superpowers plugin
2. Claude Code initializes and loads plugins
3. Plugin manifests register hooks
4. SessionStart event fires
5. Hook command is executed
6. Polyglot wrapper launches bash script
7. `session-start` reads SKILL.md and builds JSON output
8. Platform detection determines output format
9. JSON is returned to Claude Code
10. Context is injected into system context
11. User's first message sees full skill context already present

---

## Part 3: Multi-Harness Support Architecture

### 3.1 Harness Registry

The superpowers system supports **six distinct harnesses**:

| Harness | Plugin Mechanism | Hook Support | Context Injection |
|---------|-----------------|--------------|------------------|
| **Claude Code** | .claude-plugin/plugin.json | hooks.json (SessionStart) | hookSpecificOutput.additionalContext |
| **Cursor** | .cursor-plugin/plugin.json | hooks-cursor.json (sessionStart) | additional_context |
| **Copilot CLI** | NPM package entry point | SDK hooks (SessionStart) | additionalContext (SDK standard) |
| **Codex** | Symlink-based skill discovery | Native skill discovery | skill metadata (YAML frontmatter) |
| **Gemini CLI** | Extension (package.json main) | Session context (GEMINI.md) | GEMINI.md references |
| **OpenCode** | .opencode/plugins/superpowers.js | experimental.chat.messages.transform | Bootstrap context via plugin hook |

---

### 3.2 Plugin Manifests

#### Claude Code Plugin Manifest
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/.claude-plugin/plugin.json`

Provides: name, description, version, author, homepage, repository, license, keywords

#### Cursor Plugin Manifest
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/.cursor-plugin/plugin.json`

**Key Differences from Claude Code:**
- Explicit `skills: "./skills/"` field
- Explicit `agents: "./agents/"` field
- Explicit `commands: "./commands/"` field
- Explicit `hooks: "./hooks/hooks-cursor.json"` field
- Uses camelCase `displayName`

#### OpenCode Plugin (JavaScript)
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/.opencode/plugins/superpowers.js`

**Two-Hook Approach:**

1. **Config Hook** — Modifies live Config object (singleton pattern), adds superpowers skills directory to discovery path
2. **Message Transform Hook** — Intercepts outgoing messages on first user input, extracts using-superpowers skill content, adds tool mapping documentation inline, injects as text part of first user message

**Avoids:** System message token bloat and model compatibility issues

#### Gemini CLI Extension
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/gemini-extension.json`

Points to `GEMINI.md` as context file. `GEMINI.md` contains references to both skills and tool mapping.

**GEMINI.md Contents:**
```
@./skills/using-superpowers/SKILL.md
@./skills/using-superpowers/references/gemini-tools.md
```

---

### 3.3 Package Metadata

**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/package.json`

```json
{
  "name": "superpowers",
  "version": "5.0.7",
  "type": "module",
  "main": ".opencode/plugins/superpowers.js"
}
```

- `type: "module"` indicates ES6 modules (used by OpenCode plugin)
- `main` points to OpenCode plugin JavaScript file
- Enables installation via git+https

---

## Part 4: Tool Name Mapping by Harness

### 4.1 Copilot CLI Mapping
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/using-superpowers/references/copilot-tools.md`

**File Operations:**
- `Read` → `view`
- `Write` → `create`
- `Edit` → `edit`

**Execution:**
- `Bash` → `bash`
- `Grep` → `grep`
- `Glob` → `glob`

**Skills & Tasks:**
- `Skill` → `skill`
- `Task` (dispatch) → `task` with `agent_type`
- `TodoWrite` → `sql` with `todos` table

**Web Access:**
- `WebFetch` → `web_fetch`
- `WebSearch` → `web_fetch` with search URL

---

### 4.2 Codex Mapping
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/using-superpowers/references/codex-tools.md`

**Key Constraints:**
- No named agent registry (only built-in roles: `default`, `explorer`, `worker`)
- Multi-agent feature must be enabled in config

**Task Dispatch Workaround:**
When dispatching named agents, load prompt file, fill placeholders, spawn worker agent with content as message parameter.

**Codex Installation:**
- Clone to `~/.codex/superpowers`
- Create symlink: `ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers`
- Or junction on Windows: `mklink /J`

---

### 4.3 Gemini CLI Mapping
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/using-superpowers/references/gemini-tools.md`

**File Operations:**
- `Read` → `read_file`
- `Write` → `write_file`
- `Edit` → `replace`

**Execution & Search:**
- `Bash` → `run_shell_command`
- `Grep` → `grep_search`
- `Glob` → `glob`

**Skills & Tasks:**
- `Skill` → `activate_skill`
- `Task` (subagents) → Not supported (falls back to single session)
- `TodoWrite` → `write_todos`

**Gemini-Specific Tools:**
- `list_directory` — List files and subdirectories
- `save_memory` — Persist facts to GEMINI.md across sessions
- `ask_user` — Request structured input
- `tracker_create_task` — Rich task management

---

## Part 5: Test Infrastructure

### 5.1 Test Directory Structure

```
tests/
├── brainstorm-server/                      # Windows hook/server lifecycle
├── claude-code/                            # Claude Code skill tests
│   ├── README.md
│   ├── run-skill-tests.sh                  # Main test runner
│   ├── test-helpers.sh                     # Assertion functions
│   ├── test-subagent-driven-development.sh
│   └── test-subagent-driven-development-integration.sh
├── explicit-skill-requests/                # Skill invocation tests
├── opencode/                               # OpenCode tests
├── skill-triggering/                       # Auto-trigger tests
└── subagent-driven-dev/                    # Integration tests
```

---

### 5.2 Claude Code Test Suite

#### Test Runner: run-skill-tests.sh
**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/tests/claude-code/run-skill-tests.sh`

**Features:**
- Checks Claude Code CLI is installed
- Supports `--verbose`, `--test`, `--timeout`, `--integration` flags
- Timeout default: 300 seconds (5 minutes)
- Runs fast unit tests by default
- Integration tests available with `--integration` flag

**Invocation:**
```bash
./run-skill-tests.sh                          # All fast tests
./run-skill-tests.sh --integration            # Include integration tests
./run-skill-tests.sh --test test-file.sh      # Specific test
./run-skill-tests.sh --verbose                # Show full output
```

#### Test Helpers: test-helpers.sh
**Functions:**
- `run_claude "prompt" [timeout]` — Run Claude headless
- `assert_contains output pattern "test name"` — Check pattern exists
- `assert_not_contains output pattern "test name"` — Check pattern absent
- `assert_count output pattern count "test name"` — Check exact count
- `assert_order output pattern_a pattern_b "name"` — Verify order
- `create_test_project` — Create temp test dir
- `create_test_plan "$dir" "plan-name"` — Create sample plan

---

### 5.3 Test Coverage

**Fast Tests (default run):**
- `test-subagent-driven-development.sh` (~2 minutes)
  - Verifies skill loading
  - Tests workflow ordering
  - Checks self-review requirements

**Integration Tests (`--integration` flag):**
- `test-subagent-driven-development-integration.sh` (~10-30 minutes)
  - Creates real Node.js test project
  - Creates implementation plan with 2 tasks
  - Executes full subagent-driven-development workflow
  - Verifies plan read once at start
  - Checks task text provided to subagents
  - Confirms subagents perform self-review
  - Validates spec compliance review before code quality
  - Ensures working code is produced

---

## Part 6: SessionStart Flow Trace

### Complete Execution Sequence

```
[1] User starts Claude Code
    ↓
[2] Claude Code initializes plugin system
    ↓
[3] Plugin discovers manifests (hooks.json or hooks-cursor.json)
    ↓
[4] Plugin registers hooks
    ↓
[5] User starts a new session (SessionStart event)
    ↓
[6] Hook system fires SessionStart hook
    Command: "${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd" session-start
    ↓
[7] run-hook.cmd executes (polyglot wrapper)
    ├─ On Windows: CMD.exe interprets, searches for bash.exe, launches it
    └─ On Unix: bash interprets as shell script, runs directly
    ↓
[8] session-start script executes
    ├─ Resolves plugin root directory
    ├─ Checks for legacy ~/.config/superpowers/skills
    ├─ Reads using-superpowers/SKILL.md (full file)
    ├─ Escapes content for JSON embedding
    ├─ Detects platform via environment variables:
    │  ├─ CURSOR_PLUGIN_ROOT set? → Cursor
    │  ├─ CLAUDE_PLUGIN_ROOT set and COPILOT_CLI unset? → Claude Code
    │  └─ COPILOT_CLI=1 or unknown? → Copilot CLI
    └─ Outputs JSON with platform-specific format
    ↓
[9] Hook system processes JSON
    ├─ Cursor: injects additional_context into session
    ├─ Claude Code: injects hookSpecificOutput.additionalContext
    └─ Copilot CLI: injects additionalContext
    ↓
[10] Context is injected into system context (NOT user message)
     Contains:
     - <EXTREMELY_IMPORTANT> wrapper
     - Full using-superpowers skill content
     - "You have superpowers" statement
     - Legacy migration warning (if applicable)
     ↓
[11] User's first message arrives
     ├─ System context already contains skill guidance
     ├─ Model has read using-superpowers before seeing user input
     ├─ Model enforces skill-check discipline before responding
     └─ First response includes relevant skill invocations
```

---

## Part 7: Installation Methods

### By Harness

**Claude Code (Official Marketplace):**
```bash
/plugin install superpowers@claude-plugins-official
```

**Claude Code (Community Marketplace):**
```bash
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

**Cursor:**
```text
/add-plugin superpowers
```

**Copilot CLI:**
```bash
copilot plugin marketplace add obra/superpowers-marketplace
copilot plugin install superpowers@superpowers-marketplace
```

**Codex:**
```bash
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
mkdir -p ~/.agents/skills
ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
```

**Gemini CLI:**
```bash
gemini extensions install https://github.com/obra/superpowers
```

**OpenCode:**
```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

---

## Part 8: Version Management

**Script:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/scripts/bump-version.sh`

**Declared Version Locations:**
1. `package.json` → `version`
2. `.claude-plugin/plugin.json` → `version`
3. `.cursor-plugin/plugin.json` → `version`
4. `.claude-plugin/marketplace.json` → `plugins.0.version`
5. `gemini-extension.json` → `version`

**Commands:**
```bash
bump-version.sh <new-version>    # Bump to new semantic version
bump-version.sh --check          # Show all versions, detect drift
bump-version.sh --audit          # Check + scan for undeclared refs
```

---

## Part 9: Special Cases & Edge Conditions

### 9.1 Legacy Skills Migration
If `~/.config/superpowers/skills/` exists (old installation), warning is detected at SessionStart and injected into context, instructing the model to tell user about migration.

### 9.2 Windows Fallback Chain
1. Try `C:\Program Files\Git\bin\bash.exe`
2. Try `C:\Program Files (x86)\Git\bin\bash.exe`
3. Try `bash` on PATH
4. Exit silently (graceful degradation)

### 9.3 Bash 5.3+ Heredoc Workaround
Session-start uses `printf` instead of heredoc to avoid hang in bash 5.3+.

### 9.4 OpenCode Token Bloat Avoidance
Plugin injects into first user message (not system message) to avoid token bloat from system message repetition.

### 9.5 Subagent Stop Marker
Using-superpowers skill contains `<SUBAGENT-STOP>` marker so subagents dispatched to execute tasks skip reading the skill.

---

## Appendix: Key Files Index

| File | Purpose | Lines |
|------|---------|-------|
| hooks/hooks.json | Claude Code hook registration | 1-16 |
| hooks/hooks-cursor.json | Cursor hook registration | 1-10 |
| hooks/run-hook.cmd | Polyglot wrapper (Windows + Unix) | 1-47 |
| hooks/session-start | Main hook logic (bash) | 1-58 |
| .claude-plugin/plugin.json | Claude Code manifest | 1-20 |
| .cursor-plugin/plugin.json | Cursor manifest | 1-25 |
| .opencode/plugins/superpowers.js | OpenCode plugin (JavaScript) | 1-112 |
| gemini-extension.json | Gemini CLI extension metadata | 1-6 |
| package.json | NPM package entry point | 1-6 |
| .version-bump.json | Version synchronization config | 1-19 |
| scripts/bump-version.sh | Version management script | 1-221 |
| skills/using-superpowers/SKILL.md | Master skill (injected at SessionStart) | ~350 lines |
| skills/using-superpowers/references/copilot-tools.md | Copilot CLI tool mapping | 1-52 |
| skills/using-superpowers/references/codex-tools.md | Codex tool mapping | 1-101 |
| skills/using-superpowers/references/gemini-tools.md | Gemini CLI tool mapping | 1-33 |
| tests/claude-code/run-skill-tests.sh | Test runner | 1-187 |
| tests/claude-code/test-helpers.sh | Assertion library | 1-200 |
| CLAUDE.md | Contributor guidelines | Same as AGENTS.md |
| GEMINI.md | Gemini CLI context references | 1-2 |
| docs/README.codex.md | Codex user guide | 1-127 |
| docs/README.opencode.md | OpenCode user guide | 1-130 |
| docs/windows/polyglot-hooks.md | Windows hook detailed guide | 1-213 |

---

**Research Document Complete**

Generated: 2026-04-10  
Researcher: Claude Code (Haiku 4.5)  
Repository: https://github.com/obra/superpowers

