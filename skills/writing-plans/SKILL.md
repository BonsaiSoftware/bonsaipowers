---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Research (before writing tasks)

For each technology, library, or service the spec references, run targeted research so that every code block in the plan uses verified APIs — not guessed-from-training ones. Research findings embed directly into tasks (see mapping table below), not into a separate document.

1. **Resolve current APIs via context7** — pin library versions. Get actual method signatures, config options, return types. The question is "how does X work in 2026" not "how did X work when Claude was trained." If context7 can't resolve a library, fall back to WebSearch for official docs.

2. **Best-practices skill load** (conditional on detected stack) — check if the spec's stack matches an available best-practices skill and invoke it:
   - NestJS in stack? → invoke `nestjs-best-practices`
   - React / Next.js? → invoke `vercel-react-best-practices`
   - List every loaded skill in the plan header under **Required Skills:** so the implementer loads them too.

3. **Security constraints via `owasp-security`** — does any planned task touch auth, user input, data storage, or external APIs? If yes: invoke `owasp-security`, pull the relevant OWASP patterns, and embed them as hard requirements on the task step — not optional suggestions, not footnotes. e.g. "MUST use parameterized queries" goes into the task that writes the query, not into a "security notes" appendix.

4. **Don't-hand-roll check** — for each "build X" task in the plan outline: does a maintained library already do this? Query context7: `"{problem domain} {framework} library"`. If a well-maintained library exists: rewrite the task from "implement X" to "install and configure Y". Hand-rolling what a library does well is a plan failure.

5. **Pitfall scan** — for each major library the plan depends on, query context7 or WebSearch: `"{library} common mistakes"` / `"{library} gotchas"`. Each pitfall that applies to a planned task becomes a warning constraint on that task step — e.g. *"⚠ Passport guards don't catch ExpiredTokenError — add exception filter"* goes directly above the step that sets up guards.

6. **microsoft-docs** (only if Azure / Microsoft services are involved) — use `microsoft_code_sample_search` and `microsoft_docs_search` to pull official code samples for the specific service integration. Embed relevant samples as reference code blocks in the task.

## How Research Flows Into the Plan

Research findings don't sit in a separate document — they embed directly into tasks:

| Research finding | Where it goes in the plan |
|---|---|
| Library version | Plan header **Tech Stack:** with pinned versions |
| Best-practices skills | Plan header **Required Skills:** (implementer loads these) |
| Method signature from context7 | Code blocks in task steps — actual API, not guessed |
| OWASP constraint | Task step constraint: "MUST use parameterized queries" |
| Don't-hand-roll item | Task rewritten from "build X" to "install + configure Y" |
| Pitfall | Warning line (`⚠`) above the relevant step |
| Code sample from docs | Reference code block in the task |

<!-- BONSAI TIER-2 EDIT: Research section (steps 1-6) and "How Research Flows Into the Plan" table are team-specific additions not in upstream. On upstream merge, ensure both sections survive between Scope Check and File Structure. The Plan Document Header template also has an added **Required Skills:** field — keep it. -->

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**

Careful-mode (5-step, per-task commits):
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

Speed-mode (3-step, commit per wave by controller):
- "Write test + implementation" - step
- "Run tests to verify pass" - step
- "Stage declared files" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries with pinned versions from research]

**Required Skills:** [Best-practices and security skills loaded during research, e.g. nestjs-best-practices, owasp-security]

**Flow:** speed-mode (parallel waves, commit per wave) | careful-mode (sequential, commit per task)

---
```

<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — see docs/bonsai/tier-2-edits.md -->

## Speed-Mode Plan Sections

Speed-mode plans (the Bonsai default) require three extra sections after the header and before the task list. Careful-mode plans may omit them.

### `## Dependency Graph`

One line per task, listing `blockedBy`. Task IDs are the task numbers used in the task list. Example:

```
- Task 1: (none)
- Task 2: blockedBy [Task 1]
- Task 3: blockedBy [Task 1]
- Task 4: blockedBy [Task 2, Task 3]
```

### `## Shared Infrastructure`

Files or directories that — if a task touches them — force that task to run solo in its own wave. The controller uses this list to split waves. Default inclusions the planner should always consider:

- `package.json`, `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`
- Root config: `tsconfig.json`, `.eslintrc*`, `prettier.config.*`, `vite.config.*`, `nest-cli.json`
- Migration directories: `prisma/migrations/`, `src/**/migrations/`
- Barrel exports identified for the feature (e.g. `src/index.ts`, `src/lib/index.ts`)
- Global NestJS composition: root `app.module.ts`
- CI files: `.github/workflows/*.yml`

Add any feature-specific shared files — anything where concurrent edits would corrupt state.

### `## Waves`

Computed by the planner from the graph + shared-infra list. One subsection per wave. Each wave lists the tasks that run in parallel within it. Tasks that touch shared-infra files get solo waves. Example:

```
### Wave 1 (parallel: 2 tasks)
- Task 1: User DTO
- Task 2: Auth guard stub

### Wave 2 (solo — touches package.json)
- Task 3: Install passport-jwt + wire module

### Wave 3 (parallel: 2 tasks)
- Task 4: JWT strategy
- Task 5: Refresh-token strategy
```

<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — see docs/bonsai/tier-2-edits.md -->

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Wave:** [wave number this task belongs to — matches `## Waves` section above]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

### Speed-Mode Task Template

In speed-mode plans, the task template collapses to three steps — the controller handles commits at wave boundaries, so individual tasks do not commit. The implementer is also forbidden from using `git add -A` / `git add .`; staging must be explicit by filename.

**TDD tradeoff:** the 3-step template writes test + implementation together instead of splitting red/green. This loses the "watch it fail first" protection — a test written alongside its implementation that happens to pass on first run is indistinguishable from a real TDD-authored test. The JIT context7 verification during implementation and the wave-boundary test-run before commit partially compensate. For critical or security-sensitive tasks, set `**Flow:** careful-mode` in the plan header to use the 5-step per-task flow instead.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Wave:** N

- [ ] **Step 1: Write test + implementation**

Test:
```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

Implementation:
```python
def function(input):
    return expected
```

- [ ] **Step 2: Run tests to verify pass**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 3: Stage declared files**

```bash
git add tests/path/test.py src/path/file.py
```

⚠ Do NOT use `git add -A` or `git add .`. Do NOT commit — the controller commits at wave boundary.
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review
