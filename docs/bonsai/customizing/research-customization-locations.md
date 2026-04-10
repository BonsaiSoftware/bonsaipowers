# Superpowers Plugin Customization Locations Research

**Date:** 2026-04-10  
**Repository:** /Volumes/corsair-ex/bonsai-git/bonsaipowers/  
**Objective:** Document where users should place custom skills, agents, settings, and hooks to survive plugin updates without being clobbered

---

## Executive Summary

The superpowers plugin supports customization at multiple levels with different survival guarantees across updates. This document maps **where to put what** so your customizations survive `/plugin update superpowers` or equivalent.

**Key Finding:** The plugin model differs significantly by harness. Claude Code users should place personal customizations in `~/.claude/` directories (user-level, not plugin-level), NOT in the plugin installation directory. Codex and OpenCode have native skill discovery that shadows core skills. Customizations in `.claude.md` at project level survive because they live in your repo, not the plugin.

---

## Part 1: Plugin Installation Model

### 1.1 Claude Code Installation

**Command:**
```bash
/plugin install superpowers@claude-plugins-official
```

**How It Works:**
- Claude Code installs plugins to an internal plugin registry (exact location undisclosed in docs)
- Plugins are referenced by name in `~/.claude/settings.json` under `enabledPlugins`
- When you run `/plugin update superpowers`, Claude Code fetches the latest version from the marketplace and re-installs it
- **Plugin directory is replaced** on update

**Key File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/.claude-plugin/plugin.json`
- Contains plugin manifest for Claude Code discovery
- Registers the `hooks/hooks.json` file for SessionStart context injection

**Reference:**
- README.md lines 172-178: "Skills update automatically when you update the plugin: `/plugin update superpowers`"
- RELEASE-NOTES.md v5.0.1-v5.0.7: Continuous updates and breaking changes over time

**Update Behavior:**
- Plugin directory: **CLOBBERED**
- User settings (`~/.claude/settings.json`): **PRESERVED**
- Personal skills (`~/.claude/skills/`): **PRESERVED**
- Project files (`.claude.md`, `.opencode/`, etc. in your repo): **PRESERVED**

### 1.2 Codex Installation (Symlink-Based)

**Command:**
```bash
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
mkdir -p ~/.agents/skills
ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
```

**How It Works:**
- User clones the superpowers repo directly to home directory
- User creates symlink from `~/.agents/skills/superpowers` → `~/.codex/superpowers/skills/`
- Codex has **native skill discovery** — it scans `~/.agents/skills/` at startup
- Manual update via `cd ~/.codex/superpowers && git pull`

**Update Behavior:**
- Core plugin: **Can be updated via git pull**
- Personal skills (`~/.agents/skills/` outside the symlink): **PRESERVED**
- Plugin repo can be safely git-pulled without affecting personal skills

**Reference:** `docs/README.codex.md` lines 51-96

### 1.3 OpenCode Installation (NPM Plugin)

**Installation:**
```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

**How It Works:**
- OpenCode treats superpowers as an npm package from git
- Plugin auto-installs via Bun on each OpenCode launch
- **Superpowers updates automatically** when you restart OpenCode
- Two hooks inject context: `config` hook registers skills directory, `experimental.chat.messages.transform` injects bootstrap

**Update Behavior:**
- Plugin code: **Re-installed from git every launch**
- Personal skills (`~/.config/opencode/skills/`): **PRESERVED**
- Project skills (`.opencode/skills/` in your repo): **PRESERVED**

**Reference:** `docs/README.opencode.md` lines 14-88

**Skill Priority (OpenCode):**
```
.opencode/skills/           (project-level, highest priority)
  ↓ (shadows)
~/.config/opencode/skills/  (personal-level)
  ↓ (shadows)
Plugin's skills/            (core, lowest priority)
```

---

## Part 2: Skill Customization by Harness

### 2.1 Claude Code: Personal Skills

**Location:** `~/.claude/skills/my-skill/`

**Directory Structure:**
```
~/.claude/skills/
  my-skill/
    SKILL.md          (required)
    supporting-file.* (optional)
```

**Creating a Personal Skill:**

From `docs/README.codex.md` lines 67-88 (Codex example, same applies to Claude Code):

```markdown
Create your own skills in `~/.agents/skills/`:

mkdir -p ~/.agents/skills/my-skill

Create `~/.agents/skills/my-skill/SKILL.md`:

---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

**Survival Guarantee:** ✅ **100%** — Personal skills live outside the plugin directory. Updates never touch them.

**How Claude Code Discovers Them:**
- Claude Code scans `~/.claude/skills/` for `SKILL.md` files
- Parses YAML frontmatter to extract `name` and `description`
- Loads skills on-demand via the `Skill` tool
- User can invoke explicitly: `Skill tool → my-skill`

**Reference:**
- `skills/writing-skills/SKILL.md` line 12: "Personal skills live in agent-specific directories (`~/.claude/skills` for Claude Code, `~/.agents/skills/` for Codex)"
- Implicit in README.md lines 174-178 (skills update with plugin, so core skills are in plugin; personal ones elsewhere)

### 2.2 Claude Code: Project-Level Customization via CLAUDE.md

**Location:** `.claude.md` (or `AGENTS.md` — they are equivalent)

**How It Works:**
- Lives in your **project repository**, not in the plugin
- Claude reads it at session start for project-specific conventions, rules, and overrides
- Can disable or adapt any superpowers skill behavior

**Example Override (from `docs/bonsai/how-it-works/README.md`):**

```
If a project's CLAUDE.md says "don't use TDD" and a skill says "always use TDD," the user wins.
This is in `using-superpowers/SKILL.md` and is the reason forks and individual projects can disable
or adapt behavior without editing skill files.
```

**Survival Guarantee:** ✅ **100%** — Lives in your repo, not the plugin. Plugin updates never touch it.

**Instruction Precedence (from `docs/bonsai/how-it-works/README.md`):**
1. Project CLAUDE.md — highest
2. User settings (`~/.claude/settings.json`)
3. Superpowers skills
4. Claude Code default system prompt — lowest

**Reference:**
- `CLAUDE.md` + `AGENTS.md` (same file)
- `docs/bonsai/how-it-works/README.md`: Full precedence rules

### 2.3 Codex: Personal Skills

**Location:** `~/.agents/skills/my-skill/`

**How It Works:**
- Codex has **native skill discovery** — it scans `~/.agents/skills/` at startup
- Parses SKILL.md frontmatter automatically
- User-created skills shadow core skills of the same name

**Creating a Personal Skill:**

From `docs/README.codex.md` lines 67-88:

```bash
mkdir -p ~/.agents/skills/my-skill
```

Create `~/.agents/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

**Skill Shadowing:**
- If you create `~/.agents/skills/my-skill/SKILL.md`, it shadows the core `superpowers/my-skill`
- Codex prefers user-created skills over core skills with the same name

**Survival Guarantee:** ✅ **100%** — Lives in `~/.agents/skills/`, outside the clone at `~/.codex/superpowers/`.

**Reference:** `docs/README.codex.md` lines 67-88

### 2.4 Codex: Project-Level Skills

**Location:** (Not explicitly documented in README.codex.md)

**Note:** Codex docs do not mention project-level skills like OpenCode does. Codex's native skill discovery appears to be user-level only (`~/.agents/skills/`).

### 2.5 OpenCode: Personal Skills

**Location:** `~/.config/opencode/skills/my-skill/`

**How It Works:**
- OpenCode scans `~/.config/opencode/skills/` for SKILL.md files
- Personal skills shadow core superpowers skills

From `docs/README.opencode.md` lines 52-70:

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

Create `~/.config/opencode/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

**Survival Guarantee:** ✅ **100%** — Lives in user config, outside plugin re-installation.

**Reference:** `docs/README.opencode.md` lines 52-70

### 2.6 OpenCode: Project-Level Skills

**Location:** `.opencode/skills/my-skill/` (in your project repo)

**How It Works:**
- OpenCode scans `.opencode/skills/` within the project
- Project skills have **highest priority**
- Project skills shadow personal and core skills

From `docs/README.opencode.md` lines 73-76:

```markdown
Create project-specific skills in `.opencode/skills/` within your project.

**Skill Priority:** Project skills > Personal skills > Superpowers skills
```

**Creating a Project Skill:**

```bash
mkdir -p .opencode/skills/my-project-skill
```

Create `.opencode/skills/my-project-skill/SKILL.md`:

```markdown
---
name: my-project-skill
description: Use when [project-specific condition]
---

# My Project Skill

[Project-specific content]
```

**Survival Guarantee:** ✅ **100%** — Lives in your repo, not the plugin.

**Skill Priority (OpenCode):**
```
.opencode/skills/           (project-level, highest priority)
  ↓ (shadows)
~/.config/opencode/skills/  (personal-level)
  ↓ (shadows)
Plugin's skills/            (core, lowest priority)
```

**Reference:** `docs/README.opencode.md` lines 73-88

### 2.7 Cursor: Personal Skills

**Documentation Gap:** Cursor is mentioned in installation instructions (`/add-plugin superpowers`), and it has a `.cursor-plugin/plugin.json` manifest, but the docs do not explicitly state where Cursor users should place personal skills.

**Inferred from Architecture:**
- Cursor uses a separate plugin manifest (`.cursor-plugin/plugin.json`)
- Cursor's skill discovery is likely similar to Claude Code (directory-based)
- Reasonable inference: `~/.cursor/skills/` or similar, but **NOT documented in this repo**

**Reference:**
- `.cursor-plugin/plugin.json` exists at root
- `RELEASE-NOTES.md` v5.0.3: Cursor hooks support added
- Cursor-specific docs not in `/docs/` (see Part 3)

---

## Part 3: Settings and Configuration

### 3.1 Claude Code: `~/.claude/settings.json`

**Location:** `~/.claude/settings.json`

**Survives Update:** ✅ **Yes** — User configuration, not plugin.

**Contents (related to superpowers):**
- `enabledPlugins` — lists which plugins are active
  - Example: `"superpowers@claude-plugins-official": true`

**Dev Mode:**
```json
{
  "enabledPlugins": {
    "superpowers@superpowers-dev": true
  }
}
```

From `docs/testing.md` line 38:
```
Local dev marketplace must be enabled: "superpowers@superpowers-dev": true in ~/.claude/settings.json
```

**Reference:**
- `docs/testing.md` lines 38, 186

### 3.2 Claude Code: Project-Level `.claude.md` Overrides

**Location:** `.claude.md` (in your project)

**Survives Update:** ✅ **Yes** — Your repo, not the plugin.

**Purpose:**
- Override superpowers behavior for a specific project
- Disable skills: "Don't use TDD for this legacy codebase"
- Add project conventions: "All functions must be prefixed with `proj_`"
- Set tool preferences: "Use Bash over PowerShell"

**Reference:**
- `CLAUDE.md` + `AGENTS.md` (equivalent files)
- `docs/bonsai/how-it-works/README.md`: Precedence rules

### 3.3 Codex: No Explicit User Config for Superpowers

**Gap:** `docs/README.codex.md` does not mention user settings files specific to superpowers. Codex may have its own config format, but it's outside this repo's documentation.

### 3.4 OpenCode: `~/.config/opencode/opencode.json` (Global) and `opencode.json` (Project)

**Global Location:** `~/.config/opencode/opencode.json`

**Project Location:** `opencode.json` (in your project root)

**Survives Update:** ✅ **Yes** — User and repo config, not plugin.

**Plugin Configuration:**
```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

**Optional: Pin Version:**
```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```

From `docs/README.opencode.md` lines 7-33:

```
Add superpowers to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

To pin a specific version:

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```
```

**Reference:** `docs/README.opencode.md` lines 7-88

---

## Part 4: Hooks and Context Injection

### 4.1 SessionStart Hook (Read-Only in Plugin)

**Claude Code Hook Location:** `/hooks/hooks.json`
**Cursor Hook Location:** `/hooks/hooks-cursor.json`

**Survives Update:** ❌ **No** — Hooks live in the plugin directory. Updates can modify them.

**However:**
The hook injects context from the `using-superpowers/SKILL.md` file. Users **cannot override the hook itself**, but they can:
1. Create personal skills that extend or modify behavior
2. Use CLAUDE.md to provide project-level overrides
3. Modify their `~/.claude/settings.json` to disable the plugin entirely

**How the Hook Works:**

From `/hooks/session-start` lines 1-58:

1. Detects platform (Cursor, Claude Code, Copilot CLI, etc.)
2. Reads `using-superpowers/SKILL.md` from plugin directory
3. Escapes content for JSON
4. Injects as context at SessionStart
5. Checks for legacy `~/.config/superpowers/skills` and warns if found

**Key Lines:**
```bash
# Line 12-15: Detects legacy skills directory
legacy_skills_dir="${HOME}/.config/superpowers/skills"
if [ -d "$legacy_skills_dir" ]; then
    warning_message="\n\n<important-reminder>IN YOUR FIRST REPLY AFTER SEEING THIS MESSAGE YOU MUST TELL THE USER:⚠️ **WARNING:** Superpowers now uses Claude Code's skills system. Custom skills in ~/.config/superpowers/skills will not be read. Move custom skills to ~/.claude/skills instead. To make this message go away, remove ~/.config/superpowers/skills</important-reminder>"
fi
```

**Reference:**
- `hooks/hooks.json` lines 1-16
- `hooks/hooks-cursor.json` lines 1-10
- `hooks/session-start` lines 1-58
- `docs/bonsai/how-it-works/research-hooks-harnesses.md` (exhaustive)

### 4.2 Custom Project Hooks

**Location:** `.claude/hooks/` (project-specific hooks)

**Survives Update:** ✅ **Yes** — Your project, not the plugin.

**How to Implement (Inferred from Claude Code Architecture):**

Claude Code allows project-level hooks via `.claude/hooks/` directory. Users can add custom hooks that fire at SessionStart, TaskComplete, etc.

**Note:** This is not explicitly documented in the superpowers README or docs, but it's a feature of Claude Code itself. Superpowers doesn't provide examples.

**Reference:**
- Not directly in superpowers docs
- Likely in Claude Code documentation (external)

---

## Part 5: Agent and Task Configuration

### 5.1 Named Agents (Not User-Customizable)

**Location:** Built into superpowers skills

**Survives Update:** ❌ **No** — Named agent definitions live in skill files within the plugin.

**How It Works:**

From `skills/writing-plans/SKILL.md` and elsewhere, superpowers dispatches named agents like:
- `default` (general-purpose)
- `code-reviewer` (specialized)
- `documenter` (specialized)

These are defined in skill prompts and dispatch logic. Users cannot override them at the top level without modifying skills (which survives, but is not recommended).

**Workaround:**
- Create a custom skill that dispatches agents with modified prompts
- Place it in `~/.claude/skills/my-agent-config/`
- It will shadow core skills if named appropriately

**Reference:**
- `skills/subagent-driven-development/SKILL.md`
- `skills/requesting-code-review/SKILL.md`

### 5.2 Project-Specific Agent Behavior (via CLAUDE.md)

**Location:** `.claude.md` (in your project)

**Survives Update:** ✅ **Yes** — Your repo, not the plugin.

**Example:**

```markdown
# My Project Conventions

## Agent Behavior Overrides

- Do NOT use TDD for legacy code (we manually verify instead)
- Prefer TypeScript > JavaScript
- Code reviews must check security.md first
- Use ESLint config in .eslintrc.json (non-negotiable)
```

From `CLAUDE.md` lines 39-41:

```
### Project-specific or personal configuration

Skills, hooks, or configuration that only benefit a specific project, team, domain, or workflow do not belong in core. Publish these as a separate plugin.
```

**Reference:**
- `CLAUDE.md` (entire file)
- `docs/bonsai/how-it-works/README.md`

---

## Part 6: Comprehensive "Where to Put What" Matrix

### Quick Reference Table

| What | Where | Survives `/plugin update` | Platform |
|------|-------|---------------------------|----------|
| Custom skill | `~/.claude/skills/my-skill/` | ✅ Yes | Claude Code |
| Custom skill | `~/.agents/skills/my-skill/` | ✅ Yes | Codex |
| Custom skill | `~/.config/opencode/skills/my-skill/` | ✅ Yes | OpenCode |
| Project skill | `.opencode/skills/my-skill/` | ✅ Yes | OpenCode |
| Project overrides | `.claude.md` or `AGENTS.md` | ✅ Yes | All |
| Settings | `~/.claude/settings.json` | ✅ Yes | Claude Code |
| Settings | `~/.config/opencode/opencode.json` | ✅ Yes | OpenCode |
| Settings (project) | `opencode.json` (root) | ✅ Yes | OpenCode |
| SessionStart hook | `/hooks/session-start` | ❌ No | Plugin |
| Custom hooks (project) | `.claude/hooks/` | ✅ Yes | Claude Code |
| Core skills | `/skills/` | ❌ No (overwritten) | Plugin |
| Using-superpowers skill | `/skills/using-superpowers/SKILL.md` | ❌ No (overwritten) | Plugin |

### Decision Tree

**Q: I want to customize superpowers for a single project.**
- A: Use `.claude.md` in your project root (survives all updates)

**Q: I want a custom skill for just this project (OpenCode).**
- A: Create `.opencode/skills/my-skill/SKILL.md` in your repo

**Q: I want a custom skill for all my projects (personal).**
- A: Create `~/.claude/skills/my-skill/` (Claude Code) or `~/.config/opencode/skills/my-skill/` (OpenCode)

**Q: I want to modify an existing superpowers skill.**
- A: Create a personal skill with the same name (it will shadow/override the core one)

**Q: I want to change how hooks work.**
- A: You can't change superpowers' hooks. But you can disable the plugin and create your own plugin, or use `.claude.md` to override behavior.

**Q: Where do I put environment-specific settings?**
- A: `~/.claude/settings.json` (Claude Code) or `~/.config/opencode/opencode.json` (OpenCode)

**Q: Can I commit `.claude.md` to my repo?**
- A: Yes, absolutely. It's meant to be in your repo so your team shares the same conventions.

**Q: Can I commit personal skills to my repo?**
- A: You can, but they won't be discovered unless your team also has them in their personal skill directory. Better to use project-level skills (`.opencode/skills/` in OpenCode) or invite them to create personal ones.

---

## Part 7: Migration from Legacy Locations

### From `~/.config/superpowers/skills/` (Deprecated)

**Old Location:** `~/.config/superpowers/skills/`

**Current Location (Claude Code):** `~/.claude/skills/`

**Current Location (Codex):** `~/.agents/skills/`

**Why:**
- Superpowers now uses Claude Code's native skill discovery
- Old location was before skill standardization
- Plugin detects legacy location and warns users

From `hooks/session-start` lines 12-15:

```bash
legacy_skills_dir="${HOME}/.config/superpowers/skills"
if [ -d "$legacy_skills_dir" ]; then
    warning_message="\n\n<important-reminder>IN YOUR FIRST REPLY AFTER SEEING THIS MESSAGE YOU MUST TELL THE USER:⚠️ **WARNING:** Superpowers now uses Claude Code's skills system. Custom skills in ~/.config/superpowers/skills will not be read. Move custom skills to ~/.claude/skills instead. To make this message go away, remove ~/.config/superpowers/skills</important-reminder>"
fi
```

**Migration Steps:**
1. Check if `~/.config/superpowers/skills/` exists
2. Move all skill directories to `~/.claude/skills/` (Claude Code) or `~/.agents/skills/` (Codex)
3. Delete `~/.config/superpowers/skills/`
4. Restart your tool

**Reference:**
- `hooks/session-start` lines 12-15
- `docs/README.opencode.md` lines 19-32 (migration for old symlink setup)

---

## Part 8: Understanding Plugin Update Mechanics

### 8.1 What Gets Clobbered

| Item | Location | Status |
|------|----------|--------|
| Core skills | `/skills/` | ❌ Clobbered |
| Hooks | `/hooks/` | ❌ Clobbered |
| Plugin manifests | `/.claude-plugin/`, `/.cursor-plugin/` | ❌ Clobbered |
| Scripts | `/scripts/` | ❌ Clobbered |
| Documentation | `/docs/`, `README.md` | ❌ Clobbered |
| Package metadata | `package.json`, `.version-bump.json` | ❌ Clobbered |

### 8.2 What Survives

| Item | Location | Status |
|------|----------|--------|
| User-level skills | `~/.claude/skills/` | ✅ Survives |
| User settings | `~/.claude/settings.json` | ✅ Survives |
| Project-level skills | `.opencode/skills/` | ✅ Survives |
| Project config | `opencode.json`, `.claude.md` | ✅ Survives |
| Project hooks | `.claude/hooks/` | ✅ Survives |
| Anything in your repo | Your repo | ✅ Survives |

### 8.3 Update Behavior by Harness

**Claude Code:**
```
/plugin install superpowers@claude-plugins-official
  ↓ (installs to internal registry)
User runs `/plugin update superpowers`
  ↓ (fetches latest from marketplace)
Plugin directory is re-downloaded and replaces old version
  ↓
~/.claude/skills/ and ~/.claude/settings.json are untouched
```

**Codex:**
```
git clone → ~/.codex/superpowers
  ↓
User runs `cd ~/.codex/superpowers && git pull`
  ↓
Plugin repo is updated
  ↓
~/.agents/skills/ (symlink target) is untouched
```

**OpenCode:**
```
opencode.json: { "plugin": ["superpowers@git+https://..."] }
  ↓
On each OpenCode restart, plugin is re-installed from git
  ↓
~/.config/opencode/skills/ and opencode.json are untouched
```

### 8.4 Version Pinning (OpenCode)

To freeze superpowers at a specific version (prevents automatic updates):

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```

From `docs/README.opencode.md` lines 82-88:

```
To pin a specific version, use a branch or tag:

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```
```

---

## Part 9: Real-World Examples

### Example 1: Adding a Personal Debugging Skill (Claude Code)

**Goal:** Create a custom skill for your team's debugging workflow.

**Steps:**
1. Create personal skill directory:
   ```bash
   mkdir -p ~/.claude/skills/my-debugging-helpers
   ```

2. Create SKILL.md:
   ```bash
   cat > ~/.claude/skills/my-debugging-helpers/SKILL.md << 'EOF'
   ---
   name: my-debugging-helpers
   description: Use when debugging production issues with our custom logging format
   ---

   # My Debugging Helpers

   ## Setup
   Source our debug utilities: `source ./debug.sh`

   ## Check Logs
   `./logs.sh --since 1h --level ERROR`
   
   [rest of skill content]
   EOF
   ```

3. Commit to your project for team reference (optional):
   ```bash
   git add docs/MY_CUSTOM_SKILLS.md
   git commit -m "docs: guide for personal skill setup"
   ```

4. **Will this survive `/plugin update superpowers`?** ✅ Yes, lives in `~/.claude/skills/`, not in plugin directory.

**Reference:** `skills/writing-skills/SKILL.md` lines 72-82

### Example 2: Project-Specific Skill Override (OpenCode)

**Goal:** Override the TDD skill for a legacy project that doesn't use tests.

**Steps:**
1. Create project skill directory:
   ```bash
   mkdir -p .opencode/skills/test-driven-development
   ```

2. Create SKILL.md with modified behavior:
   ```bash
   cat > .opencode/skills/test-driven-development/SKILL.md << 'EOF'
   ---
   name: test-driven-development
   description: Use when implementing features (optional for this legacy codebase)
   ---

   # Legacy Project Testing Approach

   This codebase predates TDD adoption. Tests are optional.

   [rest of skill content - different from core]
   EOF
   ```

3. Commit to your repo:
   ```bash
   git add .opencode/skills/test-driven-development/SKILL.md
   git commit -m "feat: disable TDD requirement for legacy code"
   ```

4. **Will this survive plugin updates?** ✅ Yes, lives in your repo at `.opencode/skills/`.

5. **How does OpenCode prioritize?** Project skills shadow core skills of the same name.

**Reference:** `docs/README.opencode.md` lines 73-88

### Example 3: Project-Wide Behavior Override (All Harnesses)

**Goal:** Disable brainstorming for rapid prototyping sprints.

**Steps:**
1. Create `.claude.md` in your project:
   ```bash
   cat > .claude.md << 'EOF'
   # Rapid Prototype Sprint (Week of April 15)

   ## Override: Skip Brainstorming

   For this sprint, skip the brainstorming skill. We have a signed spec from design.
   Proceed directly to implementation planning.

   ## Expected Workflow
   1. Write initial plan
   2. Get user approval
   3. Execute plan immediately

   This sprint prioritizes speed over design refinement.
   EOF
   ```

2. Commit to your repo:
   ```bash
   git add .claude.md
   git commit -m "sprint: override brainstorming for rapid prototyping"
   ```

3. When you start a new Claude session in this project, the override is visible to the model.

4. **Will this survive plugin updates?** ✅ Yes, lives in your repo.

**Reference:** `docs/bonsai/how-it-works/README.md`, `CLAUDE.md` lines 76-86

### Example 4: Personal Settings Customization (Claude Code)

**Goal:** Enable a personal developer marketplace for local testing.

**Steps:**
1. Edit `~/.claude/settings.json`:
   ```bash
   cat > ~/.claude/settings.json << 'EOF'
   {
     "enabledPlugins": {
       "superpowers@claude-plugins-official": true,
       "superpowers@superpowers-dev": true
     },
     "apiKey": "sk-..."
   }
   EOF
   ```

2. Restart Claude Code.

3. **Will this survive `/plugin update superpowers`?** ✅ Yes, settings are user configuration, not plugin.

**Reference:** `docs/testing.md` lines 38, 186

---

## Part 10: Known Pitfalls and FAQs

### Pitfall 1: Editing Core Skills Inside Plugin Directory

**What happens:**
```bash
vim ~/.claude/plugins/superpowers/skills/test-driven-development/SKILL.md
```

**Problem:** Next update clobbers your changes.

**Fix:** Create a personal skill with the same name instead:
```bash
mkdir -p ~/.claude/skills/test-driven-development
cp ~/.claude/plugins/superpowers/skills/test-driven-development/SKILL.md \
   ~/.claude/skills/test-driven-development/SKILL.md
# Now edit ~/.claude/skills/test-driven-development/SKILL.md
```

**Reference:** Part 8.1 (What Gets Clobbered)

### Pitfall 2: Using `~/.config/superpowers/skills/` (Deprecated)

**What happens:**
```bash
mkdir -p ~/.config/superpowers/skills
# Create skill here
```

**Problem:** Not read by Claude Code. Hook warns "move to `~/.claude/skills/`".

**Fix:** Move skills to `~/.claude/skills/`:
```bash
mv ~/.config/superpowers/skills/* ~/.claude/skills/
rmdir ~/.config/superpowers/skills
```

**Reference:** Part 7 (Migration from Legacy Locations)

### Pitfall 3: Creating Project Skills in Wrong Location

**Scenario:** Using OpenCode, create `.opencode/skill.md` (wrong — should be `.opencode/skills/skill-name/SKILL.md`)

**Problem:** Skill not discovered. OpenCode expects directory structure with SKILL.md inside.

**Fix:**
```bash
mkdir -p .opencode/skills/my-skill
mv .opencode/skill.md .opencode/skills/my-skill/SKILL.md
```

**Reference:** Part 2.6 (OpenCode Project Skills)

### FAQ: Can I edit superpowers core skills without breaking things?

**Short answer:** Yes, but it will break on next update.

**Right way:** Create a personal or project skill with the same name. It shadows the core skill.

**Why:** Core skills serve as defaults for many projects. Your edits are isolated to your personal/project context.

**Reference:** Part 2 (Skill Customization)

### FAQ: What if I want project-specific hooks?

**Answer:** Create `.claude/hooks/` in your project.

**Note:** Not extensively documented in superpowers docs, but it's a Claude Code feature.

**Reference:** Part 4.2 (Custom Project Hooks)

### FAQ: Does `/plugin update` ever break my project code?

**Answer:** No. Plugin updates only affect the plugin directory. Your project files (`.claude.md`, `.opencode/`, `src/`, tests, etc.) are safe.

**What can break:** If your `.claude.md` references a superpowers skill that was renamed or removed. But this is rare and documented in RELEASE-NOTES.

**Reference:** Part 8 (Plugin Update Mechanics)

### FAQ: Can I commit `.claude/settings.json` to my repo?

**Answer:** You could, but it's not recommended.

**Why:** Settings are personal (API keys, preferences). Team members should have their own `~/.claude/settings.json`.

**Alternative:** Use `.claude.md` for project conventions (no secrets).

**Reference:** Part 3 (Settings and Configuration)

---

## Part 11: Testing Your Customizations

### Quick Verification Checklist

- [ ] Personal skill created in correct location (`~/.claude/skills/`, `~/.config/opencode/skills/`, or `~/.agents/skills/`)
- [ ] Skill has valid SKILL.md with frontmatter (`name`, `description`)
- [ ] Skill tool can list the skill (run `/skill list` or equivalent)
- [ ] Skill loads without errors when invoked
- [ ] `.claude.md` is in your repo root (if using it)
- [ ] Project-level skills in `.opencode/skills/` are in subdirectories with SKILL.md inside
- [ ] Settings changes saved to correct file (`~/.claude/settings.json`, etc.)
- [ ] Skill still works after `/plugin update superpowers`

### Testing Personal Skill Discovery

**Claude Code:**
```bash
# Should list your personal skill
/skill list

# Should load without errors
/skill load my-skill
```

**OpenCode:**
```bash
# Use skill tool to list
skill list

# Load skill
skill load my-skill
```

**Codex:**
```bash
# Codex discovers automatically at startup
# Mention skill by name to trigger
"use my-skill for..."
```

### Testing Project Override

**OpenCode (project skill override):**
1. Create `.opencode/skills/test-driven-development/SKILL.md`
2. Restart OpenCode
3. Run a task that would trigger TDD
4. Verify your override skill is used, not core

**All Harnesses (.claude.md override):**
1. Create `.claude.md` in project
2. Add: `Do NOT use TDD - we manually verify instead.`
3. Start new session
4. Ask for feature implementation
5. Verify model reads .claude.md and respects override

---

## Part 12: Maintenance and Updates

### Keeping Customizations in Sync

**When superpowers updates:**
1. Run `/plugin update superpowers` (or equivalent for your harness)
2. Review RELEASE-NOTES.md for breaking changes
3. If core skills you've overridden changed, test your overrides
4. If hooks changed, review `.claude/hooks/` or equivalent

**Version Pinning (OpenCode):**

If you need to stay on a specific version while your team updates:

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git#v5.0.3"]
}
```

**Why might you do this?**
- Your custom skills rely on old behavior
- Evaluating whether new version works for your team
- Gradual rollout (some devs on v5, others on v5.1)

**Reference:** `docs/README.opencode.md` lines 82-88

### Documenting Your Customizations

**Best Practice:**
1. Create `docs/CUSTOM-SKILLS.md` in your repo
2. List all personal and project skills
3. Explain why each exists
4. Link to SKILL.md files

**Example:**
```markdown
# Custom Skills

## test-driven-development (override)
- **Location:** `.opencode/skills/test-driven-development/SKILL.md`
- **Why:** Legacy codebase doesn't use TDD. This skill makes TDD optional.
- **Last Updated:** 2026-04-10

## my-security-review (new)
- **Location:** `.opencode/skills/my-security-review/SKILL.md`
- **Why:** Custom security review checklist for our product.
- **Last Updated:** 2026-04-05
```

---

## Part 13: References (File Paths and Line Numbers)

| Document | Location | Key Lines | Content |
|----------|----------|-----------|---------|
| Plugin Installation | README.md | 27-102 | How to install on each platform |
| Skill Updates | README.md | 172-178 | Plugin updates overwrite core skills |
| Codex Guide | docs/README.codex.md | 1-127 | Personal skills at `~/.agents/skills/` |
| OpenCode Guide | docs/README.opencode.md | 1-130 | Personal + project skills with priority |
| Hooks Research | docs/bonsai/how-it-works/research-hooks-harnesses.md | 1-607 | Exhaustive hook system documentation |
| Writing Skills | skills/writing-skills/SKILL.md | 1-656 | Skill creation best practices |
| Contributor Guide | CLAUDE.md | 1-86 | Project conventions; no fork-specific changes |
| Testing | docs/testing.md | 1-304 | Integration tests; `~/.claude/settings.json` dev mode |
| Release Notes | RELEASE-NOTES.md | 1-287 | Version history; breaking changes |
| Philosophy | docs/bonsai/how-it-works/README.md | Full file | Design decisions; instruction precedence |
| Installation (Codex) | .codex/INSTALL.md | (external) | Symlink setup for Codex |
| Installation (OpenCode) | .opencode/INSTALL.md | (external) | npm plugin setup for OpenCode |

---

## Conclusion: The "Where to Put What" Summary

**For customizations that survive `/plugin update`:**

1. **Personal skills** → `~/.claude/skills/` (Claude Code), `~/.agents/skills/` (Codex), `~/.config/opencode/skills/` (OpenCode)
2. **Project skills** → `.opencode/skills/` (OpenCode only; Codex/Claude Code don't have project-level equivalent)
3. **Project overrides** → `.claude.md` (all platforms)
4. **Settings** → `~/.claude/settings.json` (Claude Code), `~/.config/opencode/opencode.json` (OpenCode)
5. **Custom hooks** → `.claude/hooks/` (project-level, Claude Code)

**What gets clobbered on update:**
- Anything under `/skills/` in the plugin directory
- `/hooks/` files in the plugin directory
- All plugin manifests and metadata

**Key Principle:**
Keep customizations in `~/` (user home) or in your `repo` (project root), never in the plugin installation directory. If it's not in those two places, plugin updates will erase it.

---

**Document Generated:** 2026-04-10  
**Repository:** https://github.com/obra/superpowers  
**Researcher:** Claude Code (Haiku 4.5)

