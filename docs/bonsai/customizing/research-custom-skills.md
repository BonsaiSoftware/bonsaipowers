# Research: Authoring Custom Skills for Superpowers

Raw research material on the `writing-skills` skill, its supporting files, the frontmatter format used by every existing skill, the discovery mechanism, and the TDD-for-documentation methodology.

---

## Core Authority: `writing-skills/SKILL.md`

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/writing-skills/SKILL.md` (~656 lines)

### The Fundamental Principle

**Line 10:** *"Writing skills IS Test-Driven Development applied to process documentation."*

**Line 16 (the iron law):** *"If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing."*

### Frontmatter Requirements

From lines 95–103. Only **two fields** are required:

```yaml
---
name: my-skill
description: Use when <specific triggering condition>
---
```

- Max 1024 characters total across both fields
- `name`: letters, numbers, hyphens only (no special chars)
- `description`: MUST start with "Use when…" and describe **only triggering conditions**, never what the skill does
- Third-person
- Include specific symptoms, situations, contexts

### TDD Mapping for Skills (Lines 30–45)

| TDD concept | Skill creation equivalent |
|---|---|
| Test case | Pressure scenario run against a subagent |
| Test fails (RED) | Agent violates rule without the skill (baseline) |
| Test passes (GREEN) | Agent complies when the skill is present |
| Refactor | Close loopholes while maintaining compliance |

### The Critical "CSO" Warning (Lines 154–156)

Quoted verbatim:

> "Testing revealed that when a description summarizes the skill's workflow, Claude may follow the description instead of reading the full skill content. A description saying 'code review between tasks' caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO reviews."

**Implication:** Descriptions **only** describe triggering conditions. No workflow summary — ever. This is the subtlest and easiest-to-violate rule in the spec.

### Naming Conventions

**Use active voice, verb-first:**
- ✅ `creating-skills` — not `skill-creation`
- ✅ `condition-based-waiting` — not `async-test-helpers`
- Gerunds (`-ing`) are preferred for process skills

### Token Efficiency Targets (Lines 216–220)

- Getting-started workflows: **<150 words**
- Frequently-loaded skills: **<200 words total**
- Other skills: **<500 words**

### File Organization Patterns

Three shapes a skill directory can take:

1. **Self-contained** — `SKILL.md` only. All content inline.
2. **With tools** — `SKILL.md` + example files (reusable code, prompts, templates)
3. **Heavy reference** — `SKILL.md` + multiple supporting files (100+ lines each)

**Rule:** Supporting files one level deep from `SKILL.md`. No chained references.

### The Iron Law for Skill Authoring (Lines 374–393)

> "NO SKILL WITHOUT A FAILING TEST FIRST. This applies to NEW skills AND EDITS to existing skills."

- Wrote the skill before testing? Delete it. Start over.
- Edited without testing? Same violation.
- No exceptions for "simple additions" or "just documentation updates."

### Bulletproofing Against Rationalization (Lines 459–530)

Four techniques, all drawn from experience closing real loopholes:

1. **Close every loophole explicitly.** Don't assume agents understand the spirit.
2. **Address "spirit vs letter" arguments** by adding the foundational principle: *"Violating the letter of the rules is violating the spirit of the rules."*
3. **Build a rationalization table** documenting every excuse observed during testing.
4. **Create a red flags list** that makes self-check easy (e.g., "Code before test? → Delete code. Start over.").

### Persuasion Principles (`persuasion-principles.md`)

The writing-skills directory cites Meincke et al. (2025, N=28,000 conversations):

- Compliance rates move from 33% → 72% (+117%) when persuasion techniques are applied
- Most effective for discipline skills: **Authority + Commitment + Social Proof**
- Authority language ("YOU MUST", "No exceptions") eliminates decision fatigue

---

## Testing Methodology: `testing-skills-with-subagents.md`

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/writing-skills/testing-skills-with-subagents.md` (~385 lines)

### RED Phase — Baseline Testing

Run the pressure scenario **without** the skill. Document:
- What choice the agent makes
- What rationalizations it uses, verbatim
- Which pressures triggered the violation
- Patterns in excuses across runs

**Pressure types to combine (3+ for reliable failure):**
- Time (deadline, emergency)
- Sunk cost ("hours of work, wasteful to delete")
- Authority (senior/manager directives)
- Exhaustion (end of day, tired)
- Economic (job/promotion at stake)

### GREEN Phase — Write Minimal Skill

Address **only** the specific failures observed in RED. Do not add coverage for hypothetical cases.

### REFACTOR Phase — Close Loopholes

For each new rationalization found in testing:
1. Add an explicit negation in the rules
2. Create a row in the rationalization table
3. Add a red-flags list item
4. Update the description if the violation symptom should appear in the trigger
5. Re-test until bulletproof

### Meta-Testing (Lines 240–266)

When an agent violates a skill **despite having it loaded**, ask the agent directly:

> "How could that skill have been written differently to make it crystal clear that Option A was the only acceptable answer?"

Three response types:
1. **"Skill WAS clear, I chose to ignore it"** → need a stronger foundational principle
2. **"Skill should have said X"** → documentation problem; add the suggestion verbatim
3. **"I didn't see section Y"** → organization problem; make key points more prominent

---

## Frontmatter Analysis — All 14 Existing Skills

Character counts range from 111 to 247 (mean ≈ 160). All well under the 1024-char limit.

| Skill | Description (excerpt) | Style |
|---|---|---|
| **brainstorming** | *"You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior."* | Authority language, broad trigger |
| **test-driven-development** | *"Use when implementing any feature or bugfix, before writing implementation code"* | Discipline-enforcing, specific timing |
| **using-git-worktrees** | *"Use when starting feature work that needs isolation from current workspace or before executing implementation plans"* | Multiple triggers |
| **dispatching-parallel-agents** | *"Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies"* | Shortest (111 chars); concrete constraint |
| **finishing-a-development-branch** | *"Use when implementation is complete, all tests pass, and you need to decide how to integrate the work"* | Multiple conditions (and'd together) |
| **systematic-debugging** | *"Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes"* | Broad trigger on symptoms |
| **verification-before-completion** | *"Use when about to claim work is complete, fixed, or passing, before committing or creating PRs"* | Discipline-enforcing specific moment |
| **executing-plans** | *"Use when you have a written implementation plan to execute in a separate session with review checkpoints"* | Specific prerequisites |
| **writing-plans** | *"Use when you have a spec or requirements for a multi-step task, before touching code"* | Clear timing gate |
| **writing-skills** | *"Use when creating new skills, editing existing skills, or verifying skills work before deployment"* | Three triggers listed |
| **subagent-driven-development** | *"Use when executing implementation plans with independent tasks in the current session"* | Session-specific constraint |
| **requesting-code-review** | *"Use when completing tasks, implementing major features, or before merging to verify work meets requirements"* | Multiple triggers |
| **receiving-code-review** | *"Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable"* | Discipline-enforcing, conditional |
| **using-superpowers** | *"Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response"* | Broadest trigger |

**Patterns to copy:**
- Every description starts with "Use when…" (or the authority "You MUST use this…" variant)
- None describe what the skill *does* — only when to invoke it
- Multi-trigger descriptions use "or" or list form
- Prerequisites (plan written, tests passing) are explicit

---

## Skill Discovery Mechanism

### SessionStart Hook (primary)

**File:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/hooks/session-start/…`

**Critical finding:** Only **one** skill is injected at session start: `using-superpowers`.

The hook reads `skills/using-superpowers/SKILL.md` in full and injects it into the system prompt wrapped in:

```
<EXTREMELY_IMPORTANT>
You have superpowers.

**Below is the full content of your 'superpowers:using-superpowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**
```

All other 13 skills are loaded **on demand** via the `Skill` tool. The agent learns about them from the tool's built-in skill list, which is constructed from the `description` field of each skill's frontmatter.

### No central registry

- There is **no** manifest file listing all skills
- There is **no** index of skill names checked into the repo
- Discovery is dynamic — the harness enumerates skill directories and reads each `SKILL.md` frontmatter
- The `description` field is the sole search mechanism

This is why the description-writing rule is so strict: the description is effectively the skill's query handle.

---

## Supporting Files Pattern

**Most complex skill — `systematic-debugging/`:**
- `SKILL.md` (600+ lines)
- `condition-based-waiting.md`, `defense-in-depth.md`, `root-cause-tracing.md` (technique references)
- `condition-based-waiting-example.ts` (runnable TypeScript)
- `find-polluter.sh` (utility script)
- `test-academic.md`, `test-pressure-1/2/3.md` (test scenarios)
- `CREATION-LOG.md` (development history)

**Skills with subagent prompts:**
- `brainstorming/` → `spec-document-reviewer-prompt.md`, `visual-companion.md`
- `subagent-driven-development/` → `implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`
- `writing-plans/` → `plan-document-reviewer-prompt.md`

**Platform-specific references:**
- `using-superpowers/references/` → `codex-tools.md`, `copilot-tools.md`, `gemini-tools.md`

---

## Key Quotes to Anchor the Customization Guide

**On frontmatter (line 99–103):**
> "Description: Third-person, describes ONLY when to use (NOT what it does). Start with 'Use when…' to focus on triggering conditions. Include specific symptoms, situations, and contexts. NEVER summarize the skill's process or workflow."

**On the iron law (line 374–377):**
> "NO SKILL WITHOUT A FAILING TEST FIRST. This applies to NEW skills AND EDITS to existing skills."

**On bulletproofing (line 465–485):**
> "Don't just state the rule — forbid specific workarounds. Write code before test? Delete it. Start over. No exceptions: Don't keep it as 'reference', Don't 'adapt' it while writing tests, Don't look at it, Delete means delete."

**On discovery fragility (line 154–156):**
> "Testing revealed that when a description summarizes the skill's workflow, Claude may follow the description instead of reading the full skill content. A description saying 'code review between tasks' caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO reviews."

---

## Summary

Skills are **TDD for documentation**. Every custom skill should:

1. Begin life as a failing test — a pressure scenario an agent handles badly
2. Be written in minimal form to address that specific failure (GREEN)
3. Be refactored through iterative adversarial testing to close loopholes
4. Use frontmatter with *only* a `name` and a `description` that describes **when** to invoke, never **what** it does
5. Live in a directory that may optionally contain supporting references, templates, and prompts — but never chained references

The writing-skills skill itself is the canonical tutorial and should be read in full before authoring anything new.
