# Research: Superpowers Philosophy, Docs, and the "Why"

Raw research material on what superpowers believes, how it's pitched, the contributor guardrails, and how the naming/fork relationship works.

---

## PROJECT IDENTITY

**Naming resolution.** The upstream project is "superpowers" (published by `obra`). This clone at `/Volumes/corsair-ex/bonsai-git/bonsaipowers/` is an internal fork/variant: the local working directory and origin remote are `bonsaipowers`, while the upstream remote points at `obra/superpowers`. The codebase, skills, and philosophy are superpowers'; the `bonsai` prefix in this checkout and the `docs/bonsai/` directory are fork-local naming.

This distinction matters because CLAUDE.md has an explicit "no fork-specific changes" rule (see §2 below). The bonsai fork should not upstream rebranding or fork-specific features.

---

## 1. WHAT IS SUPERPOWERS? (The Pitch)

**From `README.md` lines 1–15:**

> "Superpowers is a complete software development workflow for your coding agents, built on top of a set of composable 'skills' and some initial instructions that make sure your agent uses them."

**Core workflow (README.md lines 5–15):**
1. Agent doesn't jump into code — asks clarifying questions about intent
2. Shows spec in digestible chunks for user approval
3. Creates implementation plan clear enough for "an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing" to follow
4. Launches subagent-driven-development: agents work through tasks, inspect work, continue autonomously (often 2+ hours without deviation)
5. Skills activate automatically — no special invocation needed

**Problem solved:** Replaces ad-hoc agent coding with a systematic workflow — design-first, plan-driven, test-driven, multi-agent execution with built-in review cycles.

---

## 2. CONTRIBUTOR PHILOSOPHY & 94% REJECTION POLICY

**From `CLAUDE.md`:**

### The 94% rejection rate (lines 1–9)
- Explicit warning to AI agents: "Almost every rejected PR was submitted by an agent that didn't read or didn't follow these guidelines"
- Maintainers close low-quality PRs "within hours, often with public comments like 'This pull request is slop that's made of lies'"
- **Agent's responsibility:** "Your job is to protect your human partner from that outcome. Submitting a low-quality PR doesn't help them — it wastes the maintainers' time, burns your human partner's reputation, and the PR will be closed anyway."

### Mandatory pre-PR checklist (lines 11–19)
1. Read entire `.github/PULL_REQUEST_TEMPLATE.md` with real, specific answers (not placeholders)
2. Search for existing PRs (open AND closed) addressing same problem
3. Verify it's a real problem (user experienced it, not theoretical)
4. Confirm belongs in core (not domain-specific, tool-specific, third-party)
5. Show human partner the complete diff and get explicit approval

### What will NOT be accepted (lines 29–65)
- **Third-party dependencies** — zero-dependency by design. New deps only for new harness support (IDE/CLI tool).
- **"Compliance" changes to skills** — internal philosophy differs from Anthropic's published guidance. No restructuring/rewording to "comply" without extensive eval evidence.
- **Project-specific or personal configuration** — domain-specific, personal, or workflow-specific code belongs in standalone plugins.
- **Bulk / spray-and-pray PRs** — one issue per PR, genuine understanding required. No batch processing.
- **Speculative / theoretical fixes** — must solve real problem someone actually experienced.
- **Domain-specific skills** — core skills are general-purpose only. Ask "would this be useful to someone working on a completely different kind of project?"
- **Fork-specific changes** — no fork syncing, no rebranding, no fork-specific features upstream.
- **Fabricated content** — invented claims, fabricated problem descriptions, hallucinated functionality → closed immediately.
- **Bundled unrelated changes** — split into separate PRs.

### Skill changes require evidence (lines 67–74)
- Skills are "code that shapes agent behavior," not prose
- Use `writing-skills` to develop changes with adversarial testing
- Require before/after eval results
- Cannot modify carefully-tuned content (Red Flags tables, rationalization lists, "human partner" language) without evidence

### Design philosophy requirement (lines 76–78)
> "Before proposing changes to skill design, workflow philosophy, or architecture, read existing skills and understand the project's design decisions. Superpowers has its own tested philosophy about skill design, agent behavior shaping, and terminology (e.g., 'your human partner' is deliberate, not interchangeable with 'the user'). Changes that rewrite the project's voice or restructure its approach without understanding why it exists will be rejected."

---

## 3. HARNESS-SPECIFIC DOCS

**AGENTS.md** and **GEMINI.md** are simple redirect references — they `@`-include `skills/using-superpowers/SKILL.md` and the harness-specific tool mapping (e.g., `references/gemini-tools.md`). This means harness-specific guidance is embedded in the skill files themselves via `references/` subdirectories, not in separate top-level contributor documents. The main CLAUDE.md applies across all harnesses.

---

## 4. DESIGN PHILOSOPHY: THE "WHY" BEHIND SUPERPOWERS

### Core Beliefs (README.md lines 152–157)
- **Test-Driven Development** — write tests first, always
- **Systematic over ad-hoc** — process over guessing
- **Complexity reduction** — simplicity as primary goal
- **Evidence over claims** — verify before declaring success

### "Your human partner" terminology (critical design choice)

Used 20+ times across skills (test-driven-development, receiving-code-review, systematic-debugging, verification-before-completion, etc.). Deliberate, **not** interchangeable with "user":
- Signals respect and collaborative relationship (not subservience or tool-like)
- Reminds the agent that the human retains decision authority
- Prevents agents from assuming they can override human preferences
- Built into carefully-tuned behavior-shaping content (cannot be changed without evidence)

### Why "skills" instead of just prompts?

From `writing-skills/SKILL.md`:
> "Writing skills IS Test-Driven Development applied to process documentation."

Skills are TDD for behavior: write test cases (pressure scenarios with subagents) → watch agents fail without the skill → write the skill (documentation) → watch agents comply → refactor (close loopholes). **Skills are code that shapes behavior**, not narrative guides.

### The `using-superpowers` meta-skill: why mandatory at session start?

From `using-superpowers/SKILL.md`:
- Flagged with `<EXTREMELY-IMPORTANT>`: "If you think there is even a 1% chance a skill might apply to your task, you ABSOLUTELY MUST invoke the skill"
- "IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT. This is not negotiable. This is not optional."
- Includes a Red Flags table identifying rationalizations agents use to skip skills (e.g., "This is just a simple question" → Reality: "Questions are tasks. Check for skills")

**Purpose:** Establishes skill discipline upfront, preventing drift into ad-hoc behavior.

### Zero-dependency design philosophy

CLAUDE.md line 31: "Superpowers is a zero-dependency plugin by design."

Evidence from RELEASE-NOTES.md v5.0.2 (lines 92–100):
- Replaced Express/Chokidar/WebSocket with zero-dependency Node.js server using built-in `http`, `fs`, `crypto`
- Removed ~1,200 lines of vendored node_modules
- Custom WebSocket protocol (RFC 6455 framing), native `fs.watch()` file watching

**Why:** Reduces deployment friction, improves reliability, simplifies maintenance.

### Anti-"compliance" stance (CLAUDE.md lines 35–37)

> "Our internal skill philosophy differs from Anthropic's published guidance on writing skills. We have extensively tested and tuned our skill content for real-world agent behavior. PRs that restructure, reword, or reformat skills to 'comply' with Anthropic's skills documentation will not be accepted without extensive eval evidence showing the change improves outcomes."

**Signals:** Superpowers prioritizes empirical results over conformance to external standards. It has its own battle-tested approach.

---

## 5. DOCUMENTATION & GUIDES

### Top-level docs
- **README.md** (~191 lines) — main pitch, installation (7 platforms), basic workflow, philosophy, contributing, updating
- **CLAUDE.md** (~86 lines) — contributor guidelines, 94% rejection policy, what's not accepted
- **RELEASE-NOTES.md** (100+ lines) — installation notes, upgrade guidance, bug fixes, feature summaries (v5.0.7 → v5.0.2)
- **CHANGELOG.md** — version-by-version log
- **CODE_OF_CONDUCT.md** — Contributor Covenant 2.0, enforcement contact `jesse@primeradiant.com`

### Harness-specific docs (`docs/`)
- **docs/bonsai/README.codex.md** — Codex installation (symlink-based), native skill discovery, personal skills, troubleshooting
- **docs/bonsai/README.opencode.md** — OpenCode installation (npm plugin), auto-registration via config hook, personal/project skills, updating, troubleshooting
- **docs/bonsai/testing.md** (~265 lines) — integration test framework for skills, token analysis tool, session transcript parsing, writing new tests
- **docs/bonsai/windows/** — Windows-specific notes

### Spec & plan files
- `docs/superpowers/specs/` — design documents (e.g., `2026-01-22-document-review-system-design.md`, `2026-02-19-visual-brainstorming-refactor-design.md`, `2026-03-11-zero-dep-server-design.md`, `2026-03-23-codex-compatibility-design.md`)
- `docs/superpowers/plans/` — implementation plans consumed by executing-plans / subagent-driven-development

---

## 6. INSTALLATION & GETTING STARTED

From `README.md` lines 27–102:

### Claude Code — official marketplace
```
/plugin install superpowers@claude-plugins-official
```

### Claude Code — custom marketplace
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

### Cursor
```
/add-plugin superpowers
```

### Codex
Fetch `https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md` and follow. Detailed docs: `docs/bonsai/README.codex.md`.

### OpenCode
Fetch `https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md` and follow. Detailed docs: `docs/bonsai/README.opencode.md`.

### GitHub Copilot CLI
```
copilot plugin marketplace add obra/superpowers-marketplace
copilot plugin install superpowers@superpowers-marketplace
```

### Gemini CLI
```
gemini extensions install https://github.com/obra/superpowers
gemini extensions update superpowers
```

### Verification
Start a new session and ask for something that should trigger a skill ("help me plan this feature" / "let's debug this issue"). Agent should automatically invoke the relevant skill.

---

## 7. RECENT PROJECT EVOLUTION (CHANGELOG / RELEASE NOTES)

Last ~20 entries show a consistent pattern:

- **v5.0.7 (2026-03-31)** — GitHub Copilot CLI support (SessionStart context injection, tool mapping); OpenCode fixes (skills path consistency, bootstrap as user message not system message)
- **v5.0.6 (2026-03-24)** — **Major shift:** replaced subagent review loops with inline self-review (25 min → 30s overhead, same quality). Brainstorm server session directory restructured (content/ and state/ as peers). Owner-PID lifecycle fixes for cross-user PIDs and WSL.
- **v5.0.5 (2026-03-17)** — Brainstorm server ESM fix (`.js` → `.cjs` for Node 22+); brainstorm owner-PID Windows/MSYS2 fix (skip lifecycle monitoring); stop-server.sh reliability
- **v5.0.4 (2026-03-16)** — Single whole-plan review (eliminated chunk-by-chunk); raised bar for blocking issues; reduced max review iterations 5 → 3; OpenCode one-line plugin install
- **v5.0.3 (2026-03-15)** — Cursor support (hooks-cursor.json, camelCase)
- **v5.0.2 (2026-03-11)** — Zero-dependency brainstorm server (removed all vendored node_modules)

**Pattern:** performance (reducing token overhead, removing review loops), cross-platform compatibility (Windows, Codex, Cursor, Copilot CLI), simplification (inline review, zero deps).

---

## 8. SKILL ARCHITECTURE & CORE WORKFLOW OVERVIEW

Skill categories (README.md lines 130–150):

**Testing**
- `test-driven-development`

**Debugging**
- `systematic-debugging`
- `verification-before-completion`

**Collaboration**
- `brainstorming`
- `writing-plans`
- `executing-plans`
- `dispatching-parallel-agents`
- `requesting-code-review`
- `receiving-code-review`
- `using-git-worktrees`
- `finishing-a-development-branch`
- `subagent-driven-development`

**Meta**
- `writing-skills`
- `using-superpowers`

**The flow (README.md lines 108–123):**
1. `brainstorming` → design document
2. `using-git-worktrees` → isolated workspace
3. `writing-plans` → implementation plan
4. `subagent-driven-development` OR `executing-plans` → execution
5. `test-driven-development` → during implementation (RED-GREEN-REFACTOR)
6. `requesting-code-review` → between tasks
7. `finishing-a-development-branch` → cleanup, merge decision

**Key design principle:** Agent checks for relevant skills before ANY task. Mandatory workflows, not suggestions.

---

## 9. KEY TERMINOLOGY & DESIGN CHOICES

| Term | Significance |
|------|-------------|
| **"Your human partner"** | Deliberate — signals collaboration, respects human authority. Not interchangeable with "user" or "the human." |
| **"Skills"** | Behavior-shaping documentation, not prompts. TDD applied to process guides. Each skill backed by adversarial testing. |
| **"Superpowers"** | Composite system of skills + initial instructions + activation discipline. Not one tool — a workflow. |
| **Spec** | Output of brainstorming. Presented in digestible chunks, user-approved before planning. |
| **Plan** | Output of writing-plans. Bite-sized tasks (2–5 min each) with exact file paths, complete code, test commands. |
| **Subagent-driven** | Fresh subagent per task + two-stage review (spec compliance → code quality). |
| **Zero-dependency** | Runs everywhere. No npm deps in production. Uses Node.js built-ins. Design choice, not accident. |

---

## 10. WHY THIS DESIGN MATTERS

**The fundamental bet:** Agents work better with *systematic process + behavior shaping via skill documentation + empirical eval* than with unstructured prompting or "best practices" compliance.

**Evidence from project evolution:**
- Removed subagent review loops after eval showed same quality in 50× less time (v5.0.6)
- Stayed zero-dependency even as the project scaled across 7+ platforms (v5.0.2)
- Deliberately avoided "compliance" with Anthropic's published skill guidance because internal testing proved their approach works better (CLAUDE.md)
- Required evidence before changing carefully-tuned content like Red Flags tables or rationalization lists (CLAUDE.md)

**The 94% rejection rate is a feature, not a bug.** It signals that superpowers is opinionated, tested, and not a dumping ground. PRs are judged against empirical criteria, not willingness to accept changes.

---

## SUMMARY

Superpowers is a **complete workflow system** for agent-driven software development, not a collection of prompts. Its philosophy: systematic design (brainstorming → spec → plan → execution) + test-driven skill development + empirical validation. It prioritizes real-world agent behavior over external compliance, zero dependencies over convenience, and structured process over ad-hoc agent autonomy. The 94% PR rejection rate and careful terminology ("your human partner," not "the user") reflect a project built by skeptics of agent capability — they've battle-tested every claim and only accept changes backed by evidence.
