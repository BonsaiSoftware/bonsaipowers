<!-- BONSAI ADDITION: Install instructions for the Bonsai fork. Preserve on upstream merge. -->

> **This is the Bonsai Software fork** of [obra/superpowers](https://github.com/obra/superpowers), customized with team-specific skills and Tier 2 orchestration edits. Team members should install from this repo, not upstream.

## Install (Bonsai team)

In Claude Code:

```
/plugin install git+https://github.com/BonsaiSoftware/bonsaipowers.git
```

The default branch on GitHub is `bonsai-custom` — that's where all Bonsai customization lives. The `main` branch is a clean mirror of upstream `obra/superpowers` used only for syncing; **do not install from `main`**, you'll get upstream without our edits.

To update:

```
/plugin update bonsaipowers
```

After installing, start a new session and say `brainstorm a small feature`. The first checklist step should be "Structured codebase recon" (step 1) — the agent should grep `package.json`, read `CLAUDE.md`, and find a similar existing feature before asking any clarifying questions. Later, before proposing approaches, it should run at least one `context7` query AND one `WebSearch` query (the Tier 2 research HARD-GATE). If those Bonsai-specific behaviors are missing, you're on the wrong branch.

### Required MCP servers

The Bonsai workflow depends on three MCP servers that are **not** bundled with the plugin — per the "no MCP in plugin" rule (see `CLAUDE.md`), MCPs belong in the consuming project's `.mcp.json` (shared with the team, committed to git) or the user's `~/.claude.json` (personal, not shared). The plugin ships zero MCP config so it works cleanly with both per-project and per-user setups.

| MCP | Used by | Why it's required |
|-----|---------|---------|
| **`context7`** | `brainstorming` (step 4 research HARD-GATE), `writing-plans` (research section), `executing-plans` (JIT API verification), `subagent-driven-development` (implementer prompts) | Library documentation and API signature lookups. Without it, brainstorming fails its research gate, plans ship guessed method signatures, and implementers can't verify APIs before writing code. |
| **`microsoft-docs`** | `writing-plans` (research step 6, Azure features) | Official Azure and Microsoft documentation plus code samples via `microsoft_code_sample_search`. Required whenever a plan touches an Azure service — which, for this team, is most of them. |
| **`chrome-devtools`** | `bonsai-verify-ui` | Drives real Chrome from the orchestrator's main context (`mcp__chrome-devtools__navigate_page`, `click`, `fill`, `take_snapshot`, `evaluate_script`, etc.). Without it, runtime UI verification after `subagent-driven-development` cannot run. |

Follow each MCP server's own install instructions. If any are missing, the relevant skills will surface an explicit error rather than silently degrading — but it's a lot faster to configure all three up front.

### Pinning to a specific version

For critical work where you don't want surprise updates, pin to a tag:

```
/plugin install git+https://github.com/BonsaiSoftware/bonsaipowers.git#v5.0.7
```

Current version lives in [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json). Maintainers tag stable points on `bonsai-custom` when significant Tier 2 changes ship.

### Maintainers

If you're editing this repo (not just installing it), read [`CLAUDE.md`](CLAUDE.md) and [`docs/bonsai/customizing/README.md`](docs/bonsai/customizing/README.md) before touching anything in `skills/` — the three-tier model determines what's safe to change. Local development loop is in the [Local Development section](#local-development-bonsai-fork) further down.

<!-- END BONSAI ADDITION -->

---

# Superpowers

Superpowers is a complete software development workflow for your coding agents, built on top of a set of composable "skills" and some initial instructions that make sure your agent uses them.

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do. 

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. 

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY. 

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for Claude to be able to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.


## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my opensource work](https://github.com/sponsors/obra).

Thanks! 

- Jesse


## Installation

**Note:** Installation differs by platform. Claude Code or Cursor have built-in plugin marketplaces. Codex and OpenCode require manual setup.

### Claude Code Official Marketplace

Superpowers is available via the [official Claude plugin marketplace](https://claude.com/plugins/superpowers)

Install the plugin from Claude marketplace:

```bash
/plugin install superpowers@claude-plugins-official
```

### Claude Code (via Plugin Marketplace)

In Claude Code, register the marketplace first:

```bash
/plugin marketplace add obra/superpowers-marketplace
```

Then install the plugin from this marketplace:

```bash
/plugin install superpowers@superpowers-marketplace
```

### Cursor (via Plugin Marketplace)

In Cursor Agent chat, install from marketplace:

```text
/add-plugin superpowers
```

or search for "superpowers" in the plugin marketplace.

### Codex

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

**Detailed docs:** [docs/README.codex.md](docs/README.codex.md)

### OpenCode

Tell OpenCode:

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md
```

**Detailed docs:** [docs/README.opencode.md](docs/README.opencode.md)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add obra/superpowers-marketplace
copilot plugin install superpowers@superpowers-marketplace
```

### Gemini CLI

```bash
gemini extensions install https://github.com/obra/superpowers
```

To update:

```bash
gemini extensions update superpowers
```

### Verify Installation

Start a new session in your chosen platform and ask for something that should trigger a skill (for example, "help me plan this feature" or "let's debug this issue"). The agent should automatically invoke the relevant superpowers skill.

<!-- BONSAI ADDITION: Local development section for the bonsaipowers fork. Preserve on upstream merge. -->

### Local Development (Bonsai fork)

If you've cloned this fork and want to test changes without pushing to a remote or installing through a marketplace, use Claude Code's `--plugin-dir` flag. This loads the plugin directly from your local clone for the current session only — no persistent install, no marketplace setup.

```bash
claude --plugin-dir /Volumes/corsair-ex/bonsai-git/bonsaipowers
```

**Session-scoped:** this is NOT a persistent install. Every time you launch `claude` without the flag, the plugin is not loaded. To make it ergonomic, add a shell alias:

```bash
alias claudebonsai='claude --plugin-dir /Volumes/corsair-ex/bonsai-git/bonsaipowers'
```

**Iteration loop:**

1. Edit any file in the repo (`skills/`, `agents/`, `commands/`, `hooks/`, docs, etc.)
2. Run `/reload-plugins` inside Claude Code to pick up the change — no restart needed
3. Test the change in the same session

**Smoke test** that the plugin is loaded correctly:

1. Run `/help` — you should see skills listed under the `bonsaipowers` namespace (e.g., `/bonsaipowers:brainstorming`, `/bonsaipowers:writing-plans`)
2. Say `brainstorm a small feature` in the chat — the agent's first checklist step should be "Structured codebase recon" (step 1, a Bonsai Tier 2 addition), and before proposing approaches it should run both `context7` and `WebSearch` queries (the step-4 HARD-GATE). If upstream behavior leaks through (generic "Explore project context" instead of the targeted recon, or no research queries), the Tier 2 edits aren't loaded. See `docs/bonsai/tier-2-edits.md`.

**Collision with upstream superpowers:** if you also have obra's `superpowers` plugin installed (either globally or via a marketplace), both will load and you'll see both sets of skills in `/help`. Because this fork is renamed to `bonsaipowers`, they coexist without namespace conflicts, but the duplicate skill list can be confusing. Uninstall the upstream copy while developing here if it gets in the way:

```
/plugin uninstall superpowers
```

For full maintainer documentation (three-tier skill model, upstream sync workflow, Tier 2 edit tracking), see [`docs/bonsai/customizing/README.md`](docs/bonsai/customizing/README.md) and [`CLAUDE.md`](CLAUDE.md).

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves design document.

2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.

3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps.

4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes in batches with human checkpoints.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration** 
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Batch execution with checkpoints
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read more: [Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)

## Contributing

Skills live directly in this repository. To contribute:

1. Fork the repository
2. Create a branch for your skill
3. Follow the `writing-skills` skill for creating and testing new skills
4. Submit a PR

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Skills update automatically when you update the plugin:

```bash
/plugin update superpowers
```

## License

MIT License - see LICENSE file for details

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

- **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
- **Issues**: https://github.com/obra/superpowers/issues
- **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions
