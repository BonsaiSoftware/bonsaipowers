# Research: Commands, Subagents, and the Plan-Write / Plan-Execute Workflow

> **Frozen research archive — do not load into context during routine work.** The operative content is summarized in [README.md](README.md). Read this file only when deep-diving its specific topic.

Raw research material on how the superpowers system orchestrates work end-to-end: from slash commands through subagents, plan writing, plan execution, TDD, verification, review, and branch-finishing.

---

## PART 1: SLASH COMMANDS AND SKILL DEPRECATION

### Historical Command Layer (Deprecated)
**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/commands/`

Three legacy slash commands exist but are fully deprecated in favor of skill-based execution:

#### `/brainstorm` (DEPRECATED)
- **File:** `commands/brainstorm.md` (lines 1-6)
- **Content:** Minimal stub file pointing users to `superpowers:brainstorming` skill
- **Frontmatter:** `description: "Deprecated - use the superpowers:brainstorming skill instead"`
- **User-facing instruction:** "Tell your human partner that this command is deprecated and will be removed in the next major release. They should ask you to use the 'superpowers brainstorming' skill instead."

#### `/write-plan` (DEPRECATED)
- **File:** `commands/write-plan.md` (lines 1-6)
- **Content:** Identical deprecation notice pointing to `superpowers:writing-plans` skill
- **Frontmatter:** `description: "Deprecated - use the superpowers:writing-plans skill instead"`

#### `/execute-plan` (DEPRECATED)
- **File:** `commands/execute-plan.md` (lines 1-6)
- **Content:** Identical deprecation notice pointing to `superpowers:executing-plans` skill
- **Frontmatter:** `description: "Deprecated - use the superpowers:executing-plans skill instead"`

**Transition Pattern:** All three legacy commands explicitly redirect users to the modern skill system. They serve as compatibility shims that no longer invoke any functionality directly.

---

## PART 2: BRAINSTORMING SKILL — FULL LIFECYCLE

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/brainstorming/SKILL.md`

### Skill Metadata (Frontmatter)
```yaml
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
```

### Core Mandate
**Lines 7-14:** Enforces a HARD-GATE: "Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity."

**Key principle:** Anti-pattern explicitly addressed — "This Is Too Simple To Need A Design" (lines 16-18)

### Workflow Checklist (Lines 22-32)
Eight mandatory tasks in sequence:

1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (if topic will involve visual questions) — separate message, not combined
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
4. **Propose 2-3 approaches** — with trade-offs and recommendation
5. **Present design** — in sections scaled to complexity, get user approval after each section
6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope
8. **User reviews written spec** — ask user to review before proceeding

**Terminal state:** Invoke `writing-plans` skill (line 66). Do NOT invoke frontend-design, mcp-builder, or any other implementation skill.

### Process Flow Diagram (Lines 34-64)
Graphviz flowchart shows diamond decision nodes for "Visual questions ahead?" and "User approves design?", revision loops on rejection, linear progression to `Invoke writing-plans skill` terminal state.

### Visual Companion Feature (Lines 147-164)
Optional tool — available for questions that benefit from visual treatment.

**Offering protocol:**
- One-time offer in its own message (no other content)
- Requires explicit user consent
- Per-question decision: even after acceptance, decide whether to use browser or terminal
- **Browser use cases:** mockups, wireframes, layout comparisons, architecture diagrams
- **Terminal use cases:** requirements questions, conceptual choices, tradeoff lists, text options

**Reference:** Full guide at `skills/brainstorming/visual-companion.md`

### Key Design Principles (Lines 94-105)
- Isolation and clarity — break into units with one clear purpose
- Well-defined interfaces — each unit understood independently
- Large file detection — growth is a signal of doing too much
- Follow existing codebase patterns
- Targeted improvements — no unrelated refactoring

### Spec Self-Review Checklist (Lines 116-124)
1. **Placeholder scan:** TBD, TODO, incomplete sections, vague requirements
2. **Internal consistency:** contradictions between sections?
3. **Scope check:** focused enough for a single plan?
4. **Ambiguity check:** any requirement interpretable two ways?

---

## PART 3: WRITING-PLANS SKILL

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/writing-plans/SKILL.md`

### Skill Metadata
```yaml
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
```

### Core Philosophy (Lines 10-12)
Write comprehensive plans "assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks."

### Scope Check (Lines 21-23)
If spec covers multiple independent subsystems, suggest breaking into separate plans. Each plan should produce working, testable software independently.

### File Structure Design (Lines 25-34)
Before defining tasks, **map out which files will be created or modified** and what each is responsible for.

**Principles:**
- Design units with clear boundaries and well-defined interfaces
- One clear responsibility per file
- Prefer smaller, focused files over large monolithic ones
- Files that change together should live together (split by responsibility, not technical layer)

### Bite-Sized Task Granularity (Lines 36-43)
Each step is one action (2-5 minutes):
```
"Write the failing test" - step
"Run it to make sure it fails" - step
"Implement the minimal code to make the test pass" - step
"Run the tests and make sure they pass" - step
"Commit" - step
```

### Plan Document Header (Lines 48-61)
**REQUIRED format for every plan:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

### Task Structure Template (Lines 65-104)
```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

[Full code block]

- [ ] **Step 2: Run test to verify it fails**

Run: [exact command]
Expected: [expected output]

- [ ] **Step 3: Write minimal implementation**

[Full code block]

- [ ] **Step 4: Run test to verify it passes**

Run: [exact command]
Expected: [exact output]

- [ ] **Step 5: Commit**

[Exact git commands]
```

### No Placeholders Rule (Lines 107-114)
**CRITICAL.** These are PLAN FAILURES — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code)
- Steps describing what to do without showing how
- References to undefined types/functions/methods

### Self-Review Checklist (Lines 122-132)
1. **Spec coverage:** skim spec sections — can you point to a task implementing each?
2. **Placeholder scan:** grep for red-flag phrases
3. **Type consistency:** do method signatures and property names match across tasks?

### Execution Handoff (Lines 134-152)
After saving, offer two options:

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration. REQUIRED SUB-SKILL: `superpowers:subagent-driven-development`

**2. Inline Execution** — execute tasks in same session, batch execution with checkpoints. REQUIRED SUB-SKILL: `superpowers:executing-plans`

---

## PART 4: EXECUTING-PLANS SKILL

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/executing-plans/SKILL.md`

### Skill Metadata
```yaml
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
```

### Three-Step Process (Lines 18-36)

**Step 1: Load and Review Plan**
1. Read plan file
2. Review critically — identify questions/concerns
3. If concerns: raise with human partner BEFORE starting
4. If none: create TodoWrite and proceed

**Step 2: Execute Tasks**
1. Mark task as in_progress
2. Follow each step exactly
3. Run verifications as specified
4. Mark completed

**Step 3: Complete Development**
After all tasks pass:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- REQUIRED SUB-SKILL: `superpowers:finishing-a-development-branch`

### When to Stop and Ask (Lines 40-46)
STOP immediately when:
- Hit a blocker (missing dep, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- Don't understand an instruction
- Verification fails repeatedly

### Integration Requirements (Lines 66-70)
- `superpowers:using-git-worktrees` — REQUIRED: set up isolated workspace before starting
- `superpowers:writing-plans` — creates the plan this skill executes
- `superpowers:finishing-a-development-branch` — completes the work

---

## PART 5: SUBAGENT-DRIVEN DEVELOPMENT SKILL

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/subagent-driven-development/SKILL.md`

### Skill Metadata
```yaml
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
```

### Core Principle (Lines 10-11)
"Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration"

### Decision Tree (Lines 14-31)
```
Have implementation plan?
  → yes: Tasks mostly independent?
    → yes: Stay in this session?
      → yes: subagent-driven-development (RECOMMENDED)
      → no:  executing-plans (separate session)
    → no (tightly coupled): Manual execution or brainstorm first
  → no: Manual execution or brainstorm first
```

### The Process Flowchart (Lines 42-84)
Per-task workflow:
1. Dispatch implementer subagent (`./implementer-prompt.md`)
2. Implementer asks questions? → answer, re-dispatch
3. Implementer implements, tests, commits, self-reviews
4. Dispatch spec reviewer subagent (`./spec-reviewer-prompt.md`)
5. Spec reviewer confirms code matches spec?
   - No: Implementer fixes gaps → re-review
   - Yes: continue
6. Dispatch code quality reviewer subagent (`./code-quality-reviewer-prompt.md`)
7. Code quality reviewer approves?
   - No: Implementer fixes → re-review
   - Yes: mark task complete

After all tasks:
1. Dispatch final code reviewer for entire implementation
2. Use `superpowers:finishing-a-development-branch`

### Model Selection Strategy (Lines 88-100)
- **Mechanical tasks** (isolated functions, 1-2 files): fast/cheap model
- **Integration tasks** (multi-file coordination): standard model
- **Architecture/design/review**: most capable model

### Handling Implementer Status (Lines 102-118)
- **DONE** → proceed to spec review
- **DONE_WITH_CONCERNS** → read concerns, address correctness issues before review, note observations and proceed
- **NEEDS_CONTEXT** → provide missing info, re-dispatch
- **BLOCKED** → assess: context problem (re-dispatch), needs more reasoning (stronger model), too large (break up), plan wrong (escalate)

### Prompt Templates (Lines 121-124)
- `./implementer-prompt.md`
- `./spec-reviewer-prompt.md`
- `./code-quality-reviewer-prompt.md`

### Advantages (Lines 202-226)

**vs. manual execution:**
- Subagents follow TDD naturally
- Fresh context per task
- Parallel-safe
- Subagents can ask questions

**vs. executing-plans (inline):**
- Same session — no context switch
- Continuous progress
- Automatic review checkpoints

**Quality gates:**
- Self-review before handoff
- Two-stage review: spec compliance, then code quality
- Review loops ensure fixes work

**Cost:**
- More subagent invocations (implementer + 2 reviewers per task)
- Controller does prep
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

---

## PART 6: SUPPORTING SKILLS AND WORKFLOW STAGES

### Test-Driven Development Skill
**Location:** `skills/test-driven-development/SKILL.md`

**Core Iron Law (Line 34):**
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

**RED-GREEN-REFACTOR Cycle:**
1. RED — write failing test
2. Verify RED — watch it fail correctly
3. GREEN — simplest code to pass
4. Verify GREEN — watch it pass
5. REFACTOR — clean up while green

**No exceptions (38-45):** Code before test? Delete it. Start over.

**Common rationalizations defeated (256-286):**
- "Too simple to test" → simple code breaks; test takes 30 seconds
- "I'll test after" → tests passing immediately prove nothing
- "Already manually tested" → ad-hoc ≠ systematic
- "Deleting X hours is wasteful" → sunk cost fallacy
- "Keep as reference, write tests first" → you'll adapt it; delete means delete
- "TDD will slow me down" → TDD faster than debugging

### Verification Before Completion Skill
**Location:** `skills/verification-before-completion/SKILL.md`

**Core Iron Law (18-21):**
```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
If you haven't run the verification command in this message, you cannot claim it passes.
```

**Gate function:**
1. IDENTIFY the proving command
2. RUN it fresh, complete
3. READ output, check exit code, count failures
4. VERIFY the claim
5. ONLY THEN make the claim

**Red flags (52-61):**
- "should", "probably", "seems to"
- Expressing satisfaction before verification
- About to commit/push/PR without verification
- Trusting agent success reports

### Systematic Debugging Skill
**Location:** `skills/systematic-debugging/SKILL.md`

**Core Iron Law (19):**
```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

**Four Phases (50-212):**
1. **Root cause** — errors, reproduction, recent changes, evidence, data flow tracing
2. **Pattern analysis** — working examples, differences, dependencies
3. **Hypothesis & testing** — one hypothesis, minimal test
4. **Implementation** — failing test, single fix, verify

**CRITICAL escalation (199-212):** If 3+ fixes failed, pattern indicates architectural problem, not hypothesis failure. STOP and discuss with human before attempting more fixes.

### Using Git Worktrees Skill
**Location:** `skills/using-git-worktrees/SKILL.md`

**Directory Priority (18-49):**
1. `.worktrees/` (preferred, hidden)
2. `worktrees/` (alternative)
3. CLAUDE.md preference
4. Ask user

**Safety Verification (51-73):** For project-local directories MUST verify ignored before creating:
```bash
git check-ignore -q .worktrees
```
If not ignored, add to `.gitignore`, commit, proceed.

**Creation Steps (75-134):**
1. Detect project name
2. `git worktree add "$path" -b "$BRANCH_NAME"`
3. Auto-detect and run setup (`npm install` / `cargo build` / `pip install -r requirements.txt` / `go mod download`)
4. Verify clean baseline (run tests) — STOP if baseline fails
5. Report location

### Finishing a Development Branch Skill
**Location:** `skills/finishing-a-development-branch/SKILL.md`

**Five-step process (18-150):**

1. **Verify tests** — if fail, STOP
2. **Determine base branch**
3. **Present exactly 4 options (no explanation):**
   1. Merge back to `<base-branch>` locally
   2. Push and create a Pull Request
   3. Keep the branch as-is
   4. Discard this work
4. **Execute choice** — merge/push+PR/keep/discard
5. **Cleanup worktree** — remove for options 1/2/4, keep for option 3

### Requesting Code Review Skill
**Location:** `skills/requesting-code-review/SKILL.md`

**Core principle:** "Review early, review often."

**When to request:**
- Mandatory: after each task in subagent-driven development, after major features, before merge to main
- Optional: when stuck, before refactoring, after fixing complex bug

**How to request (24-46):**
1. Get git SHAs (BASE_SHA, HEAD_SHA)
2. Dispatch code-reviewer subagent with template at `code-reviewer.md`
3. Fill placeholders: `{WHAT_WAS_IMPLEMENTED}`, `{PLAN_OR_REQUIREMENTS}`, `{BASE_SHA}`, `{HEAD_SHA}`, `{DESCRIPTION}`
4. Act on feedback: Critical immediately, Important before proceeding, Minor noted for later

### Receiving Code Review Skill
**Location:** `skills/receiving-code-review/SKILL.md`

**Response Pattern (16-25):**
1. READ all feedback without reacting
2. UNDERSTAND — restate requirement
3. VERIFY — check codebase reality
4. EVALUATE — technically sound for THIS codebase?
5. RESPOND — technical acknowledgment or reasoned pushback
6. IMPLEMENT — one item at a time, test each

**Forbidden (28-37):**
- "You're absolutely right!" (performative)
- "Great point!" / "Excellent feedback!"
- "Let me implement that now" (before verification)

**Handling unclear feedback:** STOP. Don't implement anything. Ask for clarification on ALL unclear items first.

**YAGNI check (90-98):** If reviewer says "implement properly", grep for actual usage. Unused? Suggest removing. Used? Implement.

### Dispatching Parallel Agents Skill
**Location:** `skills/dispatching-parallel-agents/SKILL.md`

**When to use:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem understood without cross-context
- No shared state

**Don't use when:**
- Failures related (one fix might address others)
- Need full system context
- Agents would interfere

**Pattern (47-83):**
1. Identify independent domains
2. Create focused agent tasks (specific scope, clear goal, constraints, expected output)
3. Dispatch in parallel
4. Review and integrate returns

---

## PART 7: CODE-REVIEWER SUBAGENT

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/agents/code-reviewer.md`

### Agent Metadata
```yaml
name: code-reviewer
description: Use this agent when a major project step has been completed and needs to be reviewed against the original plan and coding standards.
model: inherit
```

### Review Mandate (Five Dimensions)

1. **Plan Alignment** — compare against planning document, identify deviations (improvements vs problems), verify all planned functionality
2. **Code Quality** — patterns, conventions, error handling, type safety, test coverage, security, performance
3. **Architecture** — SOLID principles, separation of concerns, loose coupling, integration, scalability
4. **Documentation** — appropriate comments, file headers, function docs, standards adherence
5. **Issue Categorization** — Critical (must fix), Important (should fix), Suggestions (nice to have); actionable recommendations with code examples

### Communication Protocol
- Ask coding agent to review and confirm if significant deviations
- Recommend plan updates if plan is wrong
- Clear fix guidance
- Acknowledge what was done well before highlighting issues

---

## PART 8: PLAN STRUCTURE AND DOCUMENT EXAMPLES

### Example Plan: Document Review System
**Location:** `docs/superpowers/plans/2026-01-22-document-review-system.md`

Plan header format:
```markdown
# Document Review System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan.

**Goal:** Add spec and plan document review loops to the brainstorming and writing-plans skills.

**Architecture:** Create reviewer prompt templates in each skill directory. Modify skill files to add review loops after document creation. Use Task tool with general-purpose subagent for reviewer dispatch.

**Tech Stack:** Markdown skill files, subagent dispatch via Task tool

**Spec:** docs/superpowers/specs/2026-01-22-document-review-system-design.md

---
```

Plan is organized into logical **chunks** ("Chunk 1: Spec Document Reviewer", "Chunk 2: Plan Document Reviewer") allowing chunk-by-chunk review. Each task lists exact file paths, complete code blocks, verification commands with expected output, and exact git commit commands.

### Example Spec: Document Review System Design
**Location:** `docs/superpowers/specs/2026-01-22-document-review-system-design.md`

Spec sections: Overview, Components (two reviewers), What each checks for (completeness, coverage, consistency, clarity, YAGNI; spec alignment, task decomposition, syntax, chunk size), Output format, Review process flowcharts, Error handling (loop termination, disagreement handling, malformed output), Files to change.

---

## PART 9: FULL DEVELOPMENT LIFECYCLE — END-TO-END

```
User Idea
  ↓
[using-superpowers] — establish skill framework
  ↓
[brainstorming] — REQUIRED HARD-GATE
  ├─ Explore project context
  ├─ Offer visual companion (if needed)
  ├─ Ask clarifying questions (one at a time)
  ├─ Propose 2-3 approaches
  ├─ Present design (sections with approval)
  ├─ Write spec to docs/superpowers/specs/YYYY-MM-DD-*-design.md
  ├─ Self-review spec
  ├─ (Optional) dispatch spec reviewer subagent
  └─ User approves spec
       ↓
[using-git-worktrees]
  ├─ Check directory priority (.worktrees > worktrees > CLAUDE.md > ask)
  ├─ Verify directory ignored (for project-local)
  ├─ Create worktree with new branch
  ├─ Run project setup
  └─ Verify baseline tests (STOP on failure)
       ↓
[writing-plans] — REQUIRED
  ├─ Map file structure
  ├─ Design bite-sized tasks (2-5 min each)
  ├─ Write complete plan with exact paths, code, commands
  ├─ Enforce no-placeholders rule
  ├─ Write to docs/superpowers/plans/YYYY-MM-DD-<feature>.md
  ├─ Self-review (coverage, placeholders, type consistency)
  └─ Offer execution choice
       ↓
[Choice Point]

OPTION A: SUBAGENT-DRIVEN DEVELOPMENT (RECOMMENDED)
  For each task:
    ├─ Dispatch implementer subagent
    │   └─ Questions? → answer and re-dispatch
    ├─ Subagent: [TDD] → implement → self-review → commit
    ├─ [verification-before-completion]
    ├─ Dispatch spec compliance reviewer
    │   └─ Issues? → implementer fixes → re-review
    ├─ Dispatch code quality reviewer
    │   └─ Issues? → implementer fixes → re-review
    └─ Mark task complete
  After all tasks: final code reviewer → [finishing-a-development-branch]

OPTION B: INLINE EXECUTION
[executing-plans]
  ├─ Load plan, review critically, create TodoWrite
  ├─ Execute all tasks (TDD throughout)
  └─ [finishing-a-development-branch]

     ↓
[finishing-a-development-branch]
  ├─ Verify tests pass (STOP if fail)
  ├─ Determine base branch
  ├─ Present 4 options
  ├─ Execute choice
  └─ Cleanup worktree (except option 3)

     ↓
Completed feature / bug fix
```

### TDD Throughout
Every implementation step uses RED → GREEN → REFACTOR. Code before test? Delete and start over.

### Code Review Throughout
- **requesting-code-review** — automatic in subagent-driven, manual in inline (between batches)
- **receiving-code-review** — technical evaluation, not performance; no "You're absolutely right!"; verify on codebase before implementing; ask on unclear items; YAGNI check

### Debugging Integration
- **systematic-debugging** mandatory when bugs occur
- 3+ fix escalation rule: architectural problem, not hypothesis failure

### Parallel Dispatch
- **dispatching-parallel-agents** for 3+ independent failure domains
- Create focused agent tasks, dispatch in parallel, integrate returns

---

## PART 10: SKILL TESTING AND EVALUATION

### Integration Testing Framework
**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/docs/testing.md`

```
tests/
├── claude-code/
│   ├── test-helpers.sh
│   ├── test-subagent-driven-development-integration.sh
│   ├── analyze-token-usage.py
│   └── run-skill-tests.sh
```

Requirements:
- Run from superpowers plugin directory (not temp)
- Claude Code installed as `claude` command
- Local dev marketplace enabled in ~/.claude/settings.json

### Integration Test: subagent-driven-development

Verifies:
1. Plan loading (read once at start)
2. Full task text provided to subagents
3. Subagents perform self-review before reporting
4. Review order (spec compliance BEFORE code quality)
5. Review loops when issues found
6. Independent verification (spec reviewer reads code independently)

How it works:
1. Setup — temp Node.js project with minimal plan
2. Execution — Claude Code headless mode with the skill
3. Verification — parse session transcript (.jsonl)
4. Token analysis — usage breakdown

### Token Analysis Tool
```bash
python3 tests/claude-code/analyze-token-usage.py \
  ~/.claude/projects/<project-dir>/<session-id>.jsonl
```
Returns breakdown by agent, total tokens, estimated cost at $3/$15 per M tokens input/output.

### Testing Skills with Subagents
**Location:** `skills/writing-skills/testing-skills-with-subagents.md`

Core: "Testing skills is just TDD applied to process documentation."

| TDD Phase | Skill Testing | What You Do |
|-----------|---------------|-------------|
| RED | Baseline test | Run scenario WITHOUT skill, watch agent fail |
| Verify RED | Capture rationalizations | Document failures verbatim |
| GREEN | Write skill | Address specific baseline failures |
| Verify GREEN | Pressure test | Run scenario WITH skill, verify compliance |
| REFACTOR | Plug holes | Find new rationalizations, add counters |
| Stay GREEN | Re-verify | Test again |

**RED Phase example:** Real scenario with time pressure ("6pm dinner at 6:30pm, code review tomorrow 9am, no tests written"). Agent rationalizes: "I already manually tested it" / "Tests after achieve same goals" / "Deleting is wasteful" / "Being pragmatic not dogmatic". Skill writer now knows what to prevent.

---

## PART 11: DECISION TREES AND WHEN TO USE SKILLS

### Using Superpowers Meta-Skill
**Location:** `skills/using-superpowers/SKILL.md`

**Core rule:** Invoke relevant or requested skills BEFORE any response or action. Even 1% chance a skill might apply = invoke to check.

**Flowchart:**
```
User message → About to enter plan mode?
  → Already brainstormed?
    → No: Invoke brainstorming skill
    → Yes: Might any skill apply?
             → Yes (even 1%): Invoke Skill tool
             → No: Respond (including clarifications)
```

**Rationalization red flags:**
"This is just a simple question" / "I need more context first" / "Let me explore first" / "I can check git/files quickly" / "Let me gather information first" / "This doesn't need a formal skill" / "I remember this skill" / "This doesn't count as a task" / "The skill is overkill" / "I'll just do this one thing first" / "This feels productive" / "I know what that means" — all equal STOP, you're rationalizing.

### Skill Priority
When multiple skills apply:
1. **Process skills first** (brainstorming, debugging) — determine HOW
2. **Implementation skills second** (frontend-design) — guide execution

"Let's build X" → brainstorming first
"Fix this bug" → debugging first

### Instruction Hierarchy
1. User's explicit instructions (CLAUDE.md, GEMINI.md) — HIGHEST
2. Superpowers skills — override default
3. Default system prompt — LOWEST

If CLAUDE.md says "don't use TDD" and skill says "always use TDD," follow user's instructions.

### Platform Adaptations
- Claude Code: Skill tool
- Copilot CLI: `skill` tool
- Gemini CLI: `activate_skill` tool

---

## PART 12: ARCHITECTURAL INSIGHTS — DESIGN PATTERNS

### Plan Structure Decomposition
**Files-first design:** map files before tasks. Locks in decomposition. One responsibility per file. Smaller, focused files. Split by responsibility, not technical layer.

### Subagent Context Isolation
Fresh subagent per task. Controller constructs exactly what subagent needs. Benefits: no context pollution, controller preserves own context, subagents stay focused, questions surface before work.

### Two-Stage Review
**Stage 1: Spec Compliance** — match the spec, no scope creep, all requirements met
**Stage 2: Code Quality** — clean architecture, error handling, type safety, tests, performance, security

Order matters: spec first (correctness of task), then quality (correctness of implementation). Review loops: implementer fixes → reviewer re-checks → repeat.

### TDD as Verification
RED forces proof that the test catches the bug. GREEN forces proof the code works. REFACTOR forces proof it stays working. Tests after the fact pass immediately and prove nothing.

### Root Cause Pattern
Four phases: root cause → pattern → hypothesis → implementation. 3+ fix escalation: architectural problem exists; stop fixing symptoms.

---

## PART 13: TECHNICAL INTEGRATION POINTS

### Git Workflow
Worktree setup → branch isolation → task commits → merge or PR.

```bash
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
# Auto-detect and run setup
npm install / cargo build / pip install -r requirements.txt / go mod download
# Verify clean baseline
npm test / cargo test / pytest / go test ./...
```

Cleanup:
- Merge locally: checkout base, pull, merge, verify, delete branch
- Push and create PR: `git push -u origin <feature>`, `gh pr create`
- Keep as-is: leave
- Discard: `git branch -D <feature>`, `git worktree remove <path>`

### Task Dispatch
**Implementer:** full task text (don't make them read files) + scene-setting context + expected output

**Spec reviewer:** plan content + spec reference — check completeness, alignment, decomposition

**Code quality reviewer:** git SHAs + changed files diff — check architecture, errors, tests, security, performance

### Cost Optimization
Model selection based on task complexity. Full plan provided upfront (no file reading overhead). Prompt caching significant cost factor.

---

## PART 14: CRITICAL RULES AND HARD GATES

### Brainstorming HARD-GATE
"Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity."

### TDD IRON LAW
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```
No exceptions. Code before test? Delete. Start over.

### Verification IRON LAW
```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
If you haven't run the verification command in this message, you cannot claim it passes.
```

### Debugging IRON LAW
```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

### Instruction Hierarchy
1. User's explicit instructions — HIGHEST
2. Superpowers skills — override default
3. Default system prompt — LOWEST

**Corollary:** "If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill."

---

## CONCLUSION

The system implements a rigorous software development workflow through composable skills that form a mandatory pipeline:

1. **Ideation → brainstorming** (HARD-GATE: design before code)
2. **Isolation → using-git-worktrees** (fresh branch, clean baseline)
3. **Planning → writing-plans** (bite-sized TDD-ready tasks)
4. **Execution → subagent-driven-development or executing-plans** (with TDD, verification, code review at every step)
5. **Integration → finishing-a-development-branch** (merge/PR/keep/discard)

**Supporting skills** for issues mid-workflow: systematic-debugging, dispatching-parallel-agents, receiving-code-review.

**Meta skills:** using-superpowers (mandatory invocation, 1% threshold), writing-skills (TDD for process docs).

Self-enforcing: hard gates prevent early implementation, TDD and verification prevent undetected bugs, two-stage reviews prevent scope creep and poor quality, mandatory skill invocation prevents "just this once" rationalization.

**Design philosophy:** Process discipline outsourced to documented skills. Agents check for relevant skills before responding. Skills override default behavior. Users can override skills through explicit instructions. Result: reliable workflow without micromanagement.
