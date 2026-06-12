# Superpowers × Claude Code — Research Notes

Research-depth notes on how the **superpowers** plugin system (this repo) works when installed into Claude Code: what skills are, how they get loaded, how they chain into a full workflow, and the philosophy behind the design.

> These docs describe the system at HEAD on 2026-04-10. Superpowers is a living project — flags, filenames, and skill contents change release-to-release. When in doubt, re-read the current `SKILL.md` files in `/skills/` rather than trusting these notes.

---

## Read in this order

**"The system in one page" below covers the operative content — for routine work, read only this README.** The four `research-*.md` files are **frozen research archives** (~160KB combined; `research-skills.md` alone is 89KB). Do not load them into context during routine work; open one only when deep-diving its specific topic:

1. **[research-philosophy.md](research-philosophy.md)** — what superpowers *is*, why skills instead of prompts, the "your human partner" terminology, the zero-dependency design, the 94%-rejection contributor policy.
2. **[research-hooks-harnesses.md](research-hooks-harnesses.md)** — how the system boots: the SessionStart hook, the polyglot `run-hook.cmd` wrapper, the `using-superpowers` injection, multi-harness adaptation.
3. **[research-skills.md](research-skills.md)** — the skill catalog: all 14 primary skills with frontmatter, core rules, red-flag tables, flowcharts. The longest doc; reference only.
4. **[research-workflow.md](research-workflow.md)** — how skills chain into the full lifecycle: brainstorm → worktree → plan → subagent-driven execution → finishing the branch.

---

## The system in one page

### What it is

Superpowers is "a complete software development workflow for your coding agents, built on top of a set of composable 'skills' and some initial instructions that make sure your agent uses them" (`README.md`). It is **not** a collection of prompts — it's an opinionated, empirically-tuned behavior system whose contents are deliberately treated as load-bearing code.

### The three layers

```
┌──────────────────────────────────────────────────────────┐
│ 1. BOOT LAYER                                            │
│    hooks/hooks.json → hooks/run-hook.cmd session-start   │
│    → reads skills/using-superpowers/SKILL.md             │
│    → injects it as SessionStart additionalContext        │
│    → fires on startup | clear | compact                  │
├──────────────────────────────────────────────────────────┤
│ 2. SKILL LAYER                                           │
│    skills/using-superpowers  (meta — required)           │
│    skills/brainstorming      (hard-gate before code)     │
│    skills/writing-plans      skills/executing-plans      │
│    skills/subagent-driven-development                    │
│    skills/test-driven-development                        │
│    skills/verification-before-completion                 │
│    skills/systematic-debugging                           │
│    skills/using-git-worktrees                            │
│    skills/requesting-code-review                         │
│    skills/receiving-code-review                          │
│    skills/dispatching-parallel-agents                    │
│    skills/finishing-a-development-branch                 │
│    skills/writing-skills     (meta — how to author)      │
├──────────────────────────────────────────────────────────┤
│ 3. EXECUTION LAYER                                       │
│    agents/code-reviewer.md        (code review subagent) │
│    commands/{brainstorm,write-plan,execute-plan}.md      │
│        → all DEPRECATED, redirect to the skills above    │
└──────────────────────────────────────────────────────────┘
```

### The trigger mechanism

When Claude Code starts a session in a project where superpowers is installed:

1. Claude Code reads `hooks/hooks.json`, which registers a `SessionStart` hook that matches the `startup`, `clear`, and `compact` events.
2. The hook runs `${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd session-start`. `run-hook.cmd` is a polyglot shell script — valid in both `cmd.exe` and bash — that dispatches to the platform-appropriate interpreter.
3. The `session-start` script reads `skills/using-superpowers/SKILL.md` and emits it via the hook's `additionalContext` JSON field.
4. Claude Code splices that content into the system prompt *before* the user's first message. The content is wrapped in `<EXTREMELY_IMPORTANT>` tags with a `<SUBAGENT-STOP>` marker so subagents skip re-reading it.
5. From that point onward the agent knows: *if there is even a 1% chance a skill might apply, invoke it via the `Skill` tool before responding*.

Other harnesses (Cursor, Copilot CLI, Codex, Gemini CLI, OpenCode) each plug in through their own mechanism but achieve the same end-state. Tool-name mappings live in `skills/using-superpowers/references/copilot-tools.md`, `codex-tools.md`, and `gemini-tools.md`.

### The skill anatomy

Every `SKILL.md` follows the same shape:

```yaml
---
name: skill-name
description: Use when <trigger conditions>...
---

<EXTREMELY_IMPORTANT> ...iron law... </EXTREMELY_IMPORTANT>

## The Rule (or: Core Principle)
...

## Flowchart (Graphviz dot)
digraph { ... }

## Red Flags
| Thought | Reality |
|---------|---------|
| "rationalization"  | "why it's wrong" |

## When to stop / escalate
...

## References
- references/something.md
- templates/foo.md
```

**Two types:**
- **Rigid skills** (TDD, verification, debugging, brainstorming) have an "iron law" that cannot be adapted away and a rationalization-blocking Red Flags table.
- **Flexible skills** (git worktrees, requesting code review, dispatching parallel agents) describe principles to adapt to context.

The skill itself tells you which type it is.

### The canonical workflow

```
[using-superpowers]  ← auto-loaded at SessionStart
         │
         ▼
[brainstorming]      ← HARD GATE: no code until the design is approved
         │           ← writes docs/superpowers/specs/YYYY-MM-DD-*-design.md
         ▼
[using-git-worktrees]← isolated workspace, clean baseline, STOP on test fail
         │
         ▼
[writing-plans]      ← bite-sized tasks, exact file paths, complete code,
         │             no placeholders, self-review for coverage
         ▼
  ┌──────┴──────┐
  │             │
  ▼             ▼
[subagent-    [executing-
 driven-       plans]
 development]  (inline in
 (default)      this session)
  │             │
  ▼             ▼
  TDD RED-GREEN-REFACTOR at every step
  verification-before-completion at every claim
  requesting-code-review ↔ receiving-code-review at every task
  systematic-debugging when bugs appear
  dispatching-parallel-agents for ≥3 independent failure domains
  │             │
  └──────┬──────┘
         ▼
[finishing-a-development-branch]
         │
         ▼
   Merge / PR / Keep / Discard
```

### The four iron laws

These are the non-negotiable rules that make the whole system coherent:

1. **Brainstorming hard-gate** — "Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity." (`skills/brainstorming/SKILL.md`)
2. **TDD** — "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST. Code before test? Delete it. Start over." (`skills/test-driven-development/SKILL.md`)
3. **Verification** — "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE. If you haven't run the verification command in this message, you cannot claim it passes." (`skills/verification-before-completion/SKILL.md`)
4. **Debugging** — "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST. If 3+ fixes failed, the pattern indicates an architectural problem — stop and discuss with the human." (`skills/systematic-debugging/SKILL.md`)

### Instruction priority

1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest
2. **Superpowers skills** — override default system prompt behavior
3. **Claude Code default system prompt** — lowest

If a project's CLAUDE.md says "don't use TDD" and a skill says "always use TDD," the user wins. This is in `using-superpowers/SKILL.md` and is the reason forks and individual projects can disable or adapt behavior without editing skill files.

### Why skills instead of prompts

From `skills/writing-skills/SKILL.md`: *"Writing skills IS Test-Driven Development applied to process documentation."*

Skills are authored the way the system itself is used: write a pressure-test scenario → run it against an agent without the skill (RED, watch it rationalize) → write minimal skill text that prevents the observed failure (GREEN) → re-test to close loopholes (REFACTOR). Every Red Flags row exists because an agent actually produced that rationalization in an eval. This is why the contributor policy is unusually strict about not "cleaning up" skill wording: the wording is eval output, not prose.

### Project identity note

This checkout lives at `/Volumes/corsair-ex/bonsai-git/bonsaipowers/` — a fork of `obra/superpowers`. All contents (skills, workflow, philosophy) are superpowers'; the `bonsai` naming is fork-local. CLAUDE.md explicitly rejects fork-specific changes or rebranding upstream.

---

## Where the interesting files live

| Topic | Path |
|---|---|
| Boot hook (Claude Code) | `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start/` |
| Boot hook (Cursor) | `hooks/hooks-cursor.json` |
| Meta skill (injected at session start) | `skills/using-superpowers/SKILL.md` |
| Tool-name mapping | `skills/using-superpowers/references/{copilot,codex,gemini}-tools.md` |
| Skills directory | `skills/<skill-name>/SKILL.md` (+ `references/`, `templates/`, prompts) |
| Review subagent | `agents/code-reviewer.md` |
| Legacy slash commands (deprecated shims) | `commands/{brainstorm,write-plan,execute-plan}.md` |
| Contributor policy | `CLAUDE.md` |
| Harness redirects | `AGENTS.md`, `GEMINI.md` |
| Multi-harness docs | `docs/bonsai/README.codex.md`, `docs/bonsai/README.opencode.md` |
| Integration tests | `tests/claude-code/` |
| Testing guide | `docs/bonsai/testing.md` |
| Example specs | `docs/superpowers/specs/` |
| Example plans | `docs/superpowers/plans/` |

---

## What these notes deliberately do NOT cover

- **Brainstorm server internals** (zero-dependency Node HTTP + WebSocket implementation from v5.0.2). Covered in `docs/superpowers/specs/2026-03-11-zero-dep-server-design.md` if you want it.
- **Visual companion flow** (browser-driven mockup tool in brainstorming). Covered in `skills/brainstorming/visual-companion.md`.
- **Individual prompt templates** inside subagent-driven-development (`implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`). Read them directly — they are short and self-explanatory.
- **Changelog detail** beyond the last ~6 versions summarized in research-philosophy.md. The CHANGELOG is authoritative.
