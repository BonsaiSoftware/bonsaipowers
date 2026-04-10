# Bonsai Superpowers Skills System: Complete Research Report

**Generated:** 2026-04-10  
**Research Scope:** Exhaustive inventory and analysis of the skills system  
**Directory:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/`

---

## Executive Summary

The Bonsai superpowers skills system is a comprehensive, TDD-derived documentation framework for enforcing agent discipline and guiding workflow. It consists of **14 primary skills** organized into foundational (meta), process, and workflow categories. All skills employ persuasion psychology, Red-Flags prevention, and rationalization-blocking patterns.

**Core Thesis:** Skills are process documentation that function like Tests-First Development for behavior change. Each skill uses RED-GREEN-REFACTOR cycles: baseline behavior without skill (RED), skill documentation (GREEN), loophole closure (REFACTOR).

---

## Part 1: Foundational Skills and Architecture

### 1.1 The Meta-Skill: `using-superpowers` (Foundation Layer)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/using-superpowers/SKILL.md`

**Frontmatter:**
- **Name:** `using-superpowers`
- **Description:** "Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions"

**Core Principle** (lines 10-16):
```
If you think there is even a 1% chance a skill might apply to what you are doing, 
you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
```

**Key Architecture Elements:**

1. **Instruction Priority Hierarchy** (lines 18-26):
   - User's explicit instructions (CLAUDE.md, GEMINI.md, AGENTS.md) — highest priority
   - Superpowers skills — override default system behavior
   - Default system prompt — lowest priority
   - **Principle:** User is always in control; skills are guardrails, not constraints

2. **Skill Invocation Flow** (lines 42-76, Graphviz flowchart):
   - **Entry point:** User message received
   - **Decision 1:** About to EnterPlanMode? Check for brainstorming completion
   - **Decision 2:** Might any skill apply? (Even 1% probability triggers invocation)
   - **Required action:** Invoke Skill tool with announcement
   - **Gate function:** If checklist exists, create TodoWrite per item
   - **Terminal state:** Follow skill exactly, then respond
   - **Graphviz format:** Uses `doublecircle` for entry/exit, `diamond` for decisions, `box` for actions

3. **Red Flags Table** (lines 78-95) — Rationalization Prevention:
   Each thought is explicitly forbidden with reality check:
   - "This is just a simple question" → Questions are tasks. Check for skills.
   - "I need more context first" → Skill check comes BEFORE clarifying questions.
   - "Let me explore the codebase first" → Skills tell you HOW to explore.
   - "I remember this skill" → Skills evolve. Read current version.
   - (11 total red flags with reality counters)

4. **Skill Priority Order** (lines 97-105):
   - **Process skills first** (brainstorming, debugging) — determine HOW to approach
   - **Implementation skills second** (frontend-design, mcp-builder) — guide execution
   - **Principle:** "Let's build X" → brainstorming first, then implementation skills

5. **Skill Types** (lines 107-113):
   - **Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.
   - **Flexible** (patterns): Adapt principles to context.
   - **Rule:** The skill itself declares its type.

**Supporting References:**
- `./references/copilot-tools.md` (48 lines) — Maps Claude Code tools to Copilot CLI equivalents
- `./references/codex-tools.md` (102 lines) — Maps to Codex tool names and workarounds
- `./references/gemini-tools.md` (mentioned but not detailed in read)

---

### 1.2 Creative Work Gatekeeper: `brainstorming` (Process Layer)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/brainstorming/SKILL.md`

**Frontmatter:**
- **Name:** `brainstorming`
- **Description:** "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."

**Core Principle** (lines 6-10):
> Help turn ideas into fully formed designs and specs through natural collaborative dialogue.
> Start by understanding the current project context, then ask questions one at a time to refine the idea. 
> Once you understand what you're building, present the design and get user approval.

**Hard Gate** (lines 12-14):
```
Do NOT invoke any implementation skill, write any code, scaffold any project, 
or take any implementation action until you have presented a design and the 
user has approved it. This applies to EVERY project regardless of perceived simplicity.
```

**Anti-Pattern Addressed** (lines 16-19):
> "This Is Too Simple To Need A Design" — Every project goes through this process. 
> A todo list, a single-function utility, a config change — all of them. 
> "Simple" projects are where unexamined assumptions cause the most wasted work.

**9-Step Checklist** (lines 21-32):
1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (conditional) — standalone message if visual questions anticipated
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
4. **Propose 2-3 approaches** — with trade-offs and recommendation
5. **Present design** — scaled to complexity, get user approval after each section
6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
7. **Spec self-review** — check for placeholders, contradictions, ambiguity, scope
8. **User reviews written spec** — ask user to review before proceeding
9. **Transition to implementation** — invoke writing-plans skill (only next skill invoked)

**Process Flow** (lines 34-76, Graphviz):
- Entry: Explore project context
- Diamond: "Visual questions ahead?"
  - YES → Send visual companion offer (own message, no other content)
  - NO → Ask clarifying questions
- Diamond: "User approves design?"
  - NO → Revise and re-present
  - YES → Write design doc
- Box: Spec self-review (fix inline, no re-review)
- Diamond: "User reviews spec?"
  - NO/Changes → Loop to write design doc
  - YES/Approved → Invoke writing-plans skill (TERMINAL STATE)

**Key Principles** (lines 138-145):
- One question at a time (no overwhelming)
- Multiple choice preferred (easier than open-ended)
- YAGNI ruthlessly (remove unnecessary features)
- Explore alternatives (always propose 2-3 approaches)
- Incremental validation (design → approval → moving on)
- Be flexible (clarify when something doesn't make sense)

**Visual Companion Feature** (lines 147-164):
- **Purpose:** Browser-based mockups, diagrams, visual options during brainstorming
- **Trigger:** "Some of what we're working on might be easier to explain if I can show it to you in a web browser..."
- **Critical Rule:** Offer MUST be its own message (no combining with questions/context)
- **Per-question decision:** For EACH question, decide whether to use browser or terminal
- **Test:** Would the user understand this better by seeing it than reading it?
  - **Browser use cases:** mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
  - **Terminal use cases:** requirements questions, conceptual choices, tradeoff lists, A/B/C text options, scope decisions
- **Reference:** Full guide at `skills/brainstorming/visual-companion.md`

**Supporting Files:**
- `./spec-document-reviewer-prompt.md` (48 lines) — Template for dispatching subagent to review written spec
  - Checks: Completeness (TODOs, placeholders), Consistency (contradictions), Clarity (ambiguity), Scope (focused enough?), YAGNI (over-engineering?)
  - Reviewer returns: Status (Approved | Issues Found), Issues list, Recommendations
- `./visual-companion.md` (multiple pages) — Complete guide for browser-based visual component
  - Server launch instructions for Claude Code, Windows, Codex, Gemini CLI
  - File I/O patterns (write HTML fragments to `screen_dir`)
  - State persistence (`state_dir/events`)
  - Per-question decision flow

---

## Part 2: Development Workflow Skills

### 2.1 Test-Driven Development: `test-driven-development` (Rigid Discipline)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/test-driven-development/SKILL.md`

**Frontmatter:**
- **Name:** `test-driven-development`
- **Description:** "Use when implementing any feature or bugfix, before writing implementation code"

**Core Principle** (lines 6-14):
```
Write the test first. Watch it fail. Write minimal code to pass.

Core principle: If you didn't watch the test fail, you don't know if it tests the right thing.

Violating the letter of the rules is violating the spirit of the rules.
```

**The Iron Law** (lines 31-45):
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST

Write code before the test? Delete it. Start over.

No exceptions:
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.
```

**RED-GREEN-REFACTOR Cycle** (lines 47-69, Graphviz):
- **RED:** Write failing test (one minimal test showing what should happen)
  - Requirements: One behavior, clear name, real code (no mocks unless unavoidable)
  - **MANDATORY:** Watch it fail (verify failure message is expected, fails because feature missing)
  - If test passes → You're testing existing behavior. Fix test.
  - If test errors → Fix error, re-run until it fails correctly.

- **GREEN:** Write simplest code to pass test
  - Just enough to pass (no features, refactoring, or improvements)
  - **MANDATORY:** Watch it pass (verify other tests still pass, output pristine)
  - If test fails → Fix code, not test.
  - If other tests fail → Fix now.

- **REFACTOR:** Clean up after green
  - Remove duplication, improve names, extract helpers
  - Keep tests green (don't add behavior)

- **REPEAT:** Next failing test for next feature

**Good vs Bad Tests** (lines 198-205, table):
| Quality | Good | Bad |
|---------|------|-----|
| Minimal | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| Clear | Name describes behavior | `test('test1')` |
| Shows intent | Demonstrates desired API | Obscures what code should do |

**Why Order Matters** (lines 206-253):
- "I'll write tests after to verify it works" → Tests written after pass immediately. Passing immediately proves nothing.
- "I already manually tested all the edge cases" → Manual testing is ad-hoc, not comprehensive.
- "Deleting X hours of work is wasteful" → Sunk cost fallacy. Working code without real tests is technical debt.
- "TDD is dogmatic, being pragmatic means adapting" → TDD IS pragmatic (finds bugs before commit, prevents regressions, documents behavior, enables refactoring).
- "Tests after achieve the same goals - it's spirit not ritual" → NO. Tests-after answer "What does this do?" Tests-first answer "What should this do?"

**Common Rationalizations** (lines 256-288, massive table + Red Flags):
- "Too simple to test" → Simple code breaks. Test takes 30 seconds.
- "I'll test after" → Tests passing immediately prove nothing.
- "Already manually tested" → Ad-hoc ≠ systematic.
- "Keep as reference, write tests first" → You'll adapt it. That's testing after. Delete means delete.
- "Need to explore first" → Fine. Throw away exploration, start with TDD.
- **Red Flags Section:** Code before test, test after implementation, test passes immediately, can't explain why test failed, tests added "later", rationalizing "just this once", manual testing claims, "spirit not ritual" arguments, "keep as reference" claims, sunk cost arguments, pragmatism claims, "this is different because..."
- **ALL of these mean: Delete code. Start over with TDD.**

**Verification Checklist** (lines 327-340):
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered
> Can't check all boxes? You skipped TDD. Start over.

**When Stuck** (lines 342-349, table):
| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

**Debugging Integration** (lines 351-355):
> Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.
> Never fix bugs without a test.

**Testing Anti-Patterns Reference** (line 357-362):
> When adding mocks or test utilities, read @testing-anti-patterns.md to avoid common pitfalls:
> - Testing mock behavior instead of real behavior
> - Adding test-only methods to production classes
> - Mocking without understanding dependencies

**Supporting File:** `./testing-anti-patterns.md` (101+ lines)
- **Iron Laws:**
  1. NEVER test mock behavior
  2. NEVER add test-only methods to production classes
  3. NEVER mock without understanding dependencies
- **Anti-Pattern 1: Testing Mock Behavior**
  - Bad: `expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument()`
  - Good: Test real component or don't mock it
  - Gate Function: Before asserting on mock → "Am I testing real component behavior or just mock existence?"
  
- **Anti-Pattern 2: Test-Only Methods in Production**
  - Bad: `session.destroy()` only used in tests (production class pollution)
  - Good: Test utilities handle cleanup, production class has no destroy()

---

### 2.2 Systematic Debugging: `systematic-debugging` (Rigid Process)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/systematic-debugging/SKILL.md`

**Frontmatter:**
- **Name:** `systematic-debugging`
- **Description:** "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes"

**Core Principle** (lines 6-14):
```
Random fixes waste time and create new bugs. Quick patches mask underlying issues.

Core principle: ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

Violating the letter of this process is violating the spirit of debugging.
```

**The Iron Law** (lines 16-22):
```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST

If you haven't completed Phase 1, you cannot propose fixes.
```

**When to Use** (lines 24-44):
- ANY technical issue: test failures, bugs in production, unexpected behavior, performance problems, build failures, integration issues
- **ESPECIALLY when:** Under time pressure, "just one quick fix" seems obvious, already tried multiple fixes, previous fix didn't work, don't fully understand issue
- **Don't skip when:** Issue seems simple, in a hurry, manager wants it fixed NOW

**Four Mandatory Phases** (lines 46-213):

**Phase 1: Root Cause Investigation** (lines 50-120)
1. **Read Error Messages Carefully**
   - Don't skip past errors or warnings
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably?
   - What are exact steps?
   - Does it happen every time?

3. **Check Recent Changes**
   - Git diff, recent commits
   - New dependencies, config changes
   - Environmental differences

4. **Gather Evidence in Multi-Component Systems** (lines 72-87)
   - When system has multiple components (CI → build → signing, API → service → database)
   - **Before proposing fixes, add diagnostic instrumentation:**
     - For EACH component boundary:
       - Log what data enters component
       - Log what data exits component
       - Verify environment/config propagation
       - Check state at each layer
   - Run once to gather evidence showing WHERE it breaks
   - THEN analyze evidence to identify failing component
   - THEN investigate that specific component
   - **Example:** Multi-layer system with environment variables, build scripts, keychain state, signing commands

5. **Trace Data Flow** (lines 110-120)
   - Reference: `root-cause-tracing.md` (complete backward tracing technique)
   - Quick version: Where does bad value originate? What called this with bad value? Keep tracing up until source.
   - **Principle:** Fix at source, not at symptom.

**Phase 2: Pattern Analysis** (lines 122-143)
1. **Find Working Examples** — Locate similar working code in same codebase
2. **Compare Against References** — If implementing pattern, read reference implementation COMPLETELY
3. **Identify Differences** — What's different between working and broken? List every difference.
4. **Understand Dependencies** — What other components, settings, config, environment?

**Phase 3: Hypothesis and Testing** (lines 145-169)
1. **Form Single Hypothesis** — State clearly: "I think X is the root cause because Y"
2. **Test Minimally** — Make SMALLEST possible change to test hypothesis
3. **Verify Before Continuing** — Did it work? Yes → Phase 4. Didn't work? Form NEW hypothesis (don't add more fixes).
4. **When You Don't Know** — Say "I don't understand X". Don't pretend. Ask for help. Research more.

**Phase 4: Implementation** (lines 171-213)
1. **Create Failing Test Case** — Simplest possible reproduction, automated if possible
   - Use `superpowers:test-driven-development` skill for writing proper failing tests
2. **Implement Single Fix** — Address root cause, ONE change at a time, no "while I'm here" improvements
3. **Verify Fix** — Test passes? No other tests broken? Issue actually resolved?
4. **If Fix Doesn't Work:**
   - Count: How many fixes have you tried?
   - If < 3: Return to Phase 1, re-analyze with new information
   - **If ≥ 3: STOP and question the architecture (step 5 below)**
   - DON'T attempt Fix #4 without architectural discussion

5. **If 3+ Fixes Failed: Question Architecture** (lines 199-213)
   - Pattern: Each fix reveals new problem in different place, fixes require massive refactoring, each fix creates new symptoms
   - STOP and question fundamentals:
     - Is this pattern fundamentally sound?
     - Are we "sticking with it through sheer inertia"?
     - Should we refactor architecture vs. continue fixing symptoms?
   - **Discuss with your human partner before attempting more fixes**
   - This is NOT a failed hypothesis — this is a wrong architecture.

**Red Flags - STOP and Follow Process** (lines 215-232):
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**
> ALL of these mean: STOP. Return to Phase 1.
> If 3+ fixes failed: Question the architecture.

**Your Human Partner's Signals You're Doing It Wrong** (lines 234-242):
- "Is that not happening?" — You assumed without verifying
- "Will it show us...?" — You should have added evidence gathering
- "Stop guessing" — You're proposing fixes without understanding
- "Ultrathink this" — Question fundamentals, not just symptoms
- "We're stuck?" (frustrated) — Your approach isn't working
> When you see these: STOP. Return to Phase 1.

**Common Rationalizations** (lines 245-256, table):
- "Issue is simple, don't need process" → Simple issues have root causes too.
- "Emergency, no time for process" → Systematic is FASTER than guess-and-check.
- "Just try this first, then investigate" → First fix sets the pattern.
- "I'll write test after confirming fix works" → Untested fixes don't stick.
- "Multiple fixes at once saves time" → Can't isolate what worked.
- "Reference too long, I'll adapt the pattern" → Partial understanding guarantees bugs.
- "I see the problem, let me fix it" → Seeing symptoms ≠ understanding root cause.
- "One more fix attempt" (after 2+ failures) → 3+ failures = architectural problem.

**Quick Reference Table** (lines 260-265):
| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

**When Process Reveals "No Root Cause"** (lines 267-276):
> If systematic investigation reveals issue is truly environmental, timing-dependent, or external:
> 1. You've completed the process
> 2. Document what you investigated
> 3. Implement appropriate handling (retry, timeout, error message)
> 4. Add monitoring/logging for future investigation
> **But:** 95% of "no root cause" cases are incomplete investigation.

**Supporting Techniques** (lines 278-296):
- **`root-cause-tracing.md`** — Trace bugs backward through call stack to find original trigger
  - 5-step process: Observe symptom → Find immediate cause → Ask "What called this?" → Keep tracing up → Find original trigger
  - Adding stack traces with `console.error()` for instrumentation
  - Using `find-polluter.sh` script to identify which test causes pollution
  - Key principle: Trace backward until finding source, then fix there (never just the symptom)
  
- **`defense-in-depth.md`** — Add validation at multiple layers after finding root cause
- **`condition-based-waiting.md`** — Replace arbitrary timeouts with condition polling

**Supporting Files:**
- `./CREATION-LOG.md` — Development history (context)
- `./condition-based-waiting.md` (102 lines) — Async testing technique
- `./condition-based-waiting-example.ts` (142 lines) — TypeScript implementation
- `./defense-in-depth.md` (113 lines) — Multi-layer validation strategy
- `./find-polluter.sh` (27 lines) — Script to identify test pollution
- `./test-academic.md`, `./test-pressure-1.md`, `./test-pressure-2.md`, `./test-pressure-3.md` — Pressure scenario documentation

---

### 2.3 Verification Before Completion: `verification-before-completion` (Rigid)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/verification-before-completion/SKILL.md`

**Frontmatter:**
- **Name:** `verification-before-completion`
- **Description:** "Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always"

**Core Principle** (lines 6-14):
```
Claiming work is complete without verification is dishonesty, not efficiency.

Core principle: Evidence before claims, always.

Violating the letter of this rule is violating the spirit of this rule.
```

**The Iron Law** (lines 16-21):
```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

If you haven't run the verification command in this message, you cannot claim it passes.
```

**The Gate Function** (lines 23-38):
```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

**Common Failures** (lines 40-50, table):
| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

**Red Flags - STOP** (lines 52-61):
- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great\!", "Perfect\!", "Done\!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

**Rationalization Prevention** (lines 63-74, table):
| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

**Key Patterns** (lines 76-106):
- **Tests:** ✅ [Run test command] [See: 34/34 pass] "All tests pass" vs ❌ "Should pass now" / "Looks correct"
- **Regression tests (TDD Red-Green):** ✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass) vs ❌ "I've written a regression test" (without red-green verification)
- **Build:** ✅ [Run build] [See: exit 0] "Build passes" vs ❌ "Linter passed" (linter doesn't check compilation)
- **Requirements:** ✅ Re-read plan → Create checklist → Verify each → Report gaps or completion vs ❌ "Tests pass, phase complete"
- **Agent delegation:** ✅ Agent reports success → Check VCS diff → Verify changes → Report actual state vs ❌ Trust agent report

**Why This Matters** (lines 108-114):
> From 24 failure memories:
> - your human partner said "I don't believe you" - trust broken
> - Undefined functions shipped - would crash
> - Missing requirements shipped - incomplete features
> - Time wasted on false completion → redirect → rework
> - Violates: "Honesty is a core value. If you lie, you'll be replaced."

**The Bottom Line** (lines 133-139):
```
No shortcuts for verification.

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
```

---

## Part 3: Planning and Implementation Skills

### 3.1 Writing Plans: `writing-plans` (Specification)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/writing-plans/SKILL.md`

**Frontmatter:**
- **Name:** `writing-plans`
- **Description:** "Use when you have a spec or requirements for a multi-step task, before touching code"

**Core Principle** (lines 6-12):
> Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**Scope Check** (lines 21-23):
> If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans.

**File Structure** (lines 25-34):
- Design units with clear boundaries and well-defined interfaces
- Each file should have one clear responsibility
- You reason best about code you can hold in context at once
- Files that change together should live together (split by responsibility, not by technical layer)
- In existing codebases, follow established patterns

**Bite-Sized Task Granularity** (lines 36-44):
> **Each step is one action (2-5 minutes):**
> - "Write the failing test" - step
> - "Run it to make sure it fails" - step
> - "Implement the minimal code to make the test pass" - step
> - "Run the tests and make sure they pass" - step
> - "Commit" - step

**Plan Document Header** (lines 46-61, required format):
```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development 
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. 
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

**Task Structure** (lines 64-104):
```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**
[COMPLETE CODE BLOCK]

- [ ] **Step 2: Run test to verify it fails**
Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**
[COMPLETE CODE BLOCK]

- [ ] **Step 4: Run test to verify it passes**
Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
```

**No Placeholders** (lines 106-114):
> Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
> - "TBD", "TODO", "implement later", "fill in details"
> - "Add appropriate error handling" / "add validation" / "handle edge cases"
> - "Write tests for the above" (without actual test code)
> - "Similar to Task N" (repeat the code)
> - Steps that describe what to do without showing how (code blocks required)
> - References to types, functions, or methods not defined in any task

**Key Reminders** (lines 116-120):
- Exact file paths always
- Complete code in every step
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

**Self-Review Process** (lines 122-132):
After writing complete plan, check:
1. **Spec coverage:** Skim each section in spec. Can you point to a task that implements it? List any gaps.
2. **Placeholder scan:** Search plan for red flags — fix them.
3. **Type consistency:** Do types, method signatures, property names match across tasks?
> If you find issues, fix them inline. No need to re-review — just fix and move on.

**Execution Handoff** (lines 134-153):
After saving the plan, offer execution choice:
- **1. Subagent-Driven (recommended)** — I dispatch fresh subagent per task, review between tasks, fast iteration
  - REQUIRED SUB-SKILL: `superpowers:subagent-driven-development`
- **2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints
  - REQUIRED SUB-SKILL: `superpowers:executing-plans`

**Supporting File:** `./plan-document-reviewer-prompt.md` — Template for spec reviewer subagent

---

### 3.2 Executing Plans: `executing-plans` (Inline Sequential)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/executing-plans/SKILL.md`

**Frontmatter:**
- **Name:** `executing-plans`
- **Description:** "Use when you have a written implementation plan to execute in a separate session with review checkpoints"

**Core Principle** (lines 6-10):
> Load plan, review critically, execute all tasks, report when complete.
> **Announce at start:** "I'm using the executing-plans skill to implement this plan."
> **Note:** Subagents work much better. If available, use `superpowers:subagent-driven-development` instead.

**Three-Step Process** (lines 16-54):
1. **Load and Review Plan**
   - Read plan file
   - Review critically — identify questions or concerns
   - If concerns: Raise them BEFORE starting
   - If no concerns: Create TodoWrite and proceed

2. **Execute Tasks**
   - For each task: Mark as in_progress
   - Follow each step exactly (plan has bite-sized steps)
   - Run verifications as specified
   - Mark as completed

3. **Complete Development**
   - After all tasks verified:
   - Announce: "I'm using the finishing-a-development-branch skill to complete this work."
   - REQUIRED SUB-SKILL: `superpowers:finishing-a-development-branch`

**When to Stop and Ask for Help** (lines 39-47):
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- Don't understand an instruction
- Verification fails repeatedly
> Ask for clarification rather than guessing.

**Remember** (lines 57-62):
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

**Integration** (lines 64-71):
- REQUIRED: `superpowers:using-git-worktrees` — Set up isolated workspace before starting
- Creates plan: `superpowers:writing-plans`
- Complete development after: `superpowers:finishing-a-development-branch`

---

## Part 4: Subagent and Parallel Work Skills

### 4.1 Subagent-Driven Development: `subagent-driven-development` (Parallel + Review)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/subagent-driven-development/SKILL.md`

**Frontmatter:**
- **Name:** `subagent-driven-development`
- **Description:** "Use when executing implementation plans with independent tasks in the current session"

**Core Principle** (lines 6-12):
> Execute plan by dispatching fresh subagent per task, with two-stage review after each: 
> spec compliance review first, then code quality review.
> 
> **Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely 
> crafting their instructions and context, you ensure they stay focused and succeed at their task.

**When to Use** (lines 14-31, decision tree):
- Have implementation plan? → Check if mostly independent tasks
- Tasks independent? → Check if staying in current session
- Staying in session? → Use subagent-driven-development
- Parallel session instead? → Use executing-plans

**Complex Process Flow** (lines 40-84, detailed Graphviz):
Per-task workflow:
1. Read plan, extract all tasks with full text, note context, create TodoWrite
2. **For each task:**
   - Dispatch implementer subagent (`./implementer-prompt.md`)
   - Implementer asks questions? → Answer questions, provide context → Re-dispatch implementer
   - Implementer implements, tests, commits, self-reviews
   - Dispatch spec reviewer subagent (`./spec-reviewer-prompt.md`)
   - Spec compliant? → YES: Dispatch code quality reviewer
   - Spec compliant? → NO: Implementer fixes spec gaps → Re-dispatch spec reviewer (loop until ✅)
   - Dispatch code quality reviewer subagent (`./code-quality-reviewer-prompt.md`)
   - Code approved? → YES: Mark task complete in TodoWrite
   - Code approved? → NO: Implementer fixes quality issues → Re-dispatch code reviewer (loop until ✅)
   - More tasks remain? → YES: Next task
   - More tasks remain? → NO: Dispatch final code reviewer for entire implementation
3. Use `superpowers:finishing-a-development-branch`

**Model Selection** (lines 87-101):
> Use the least powerful model that can handle each role to conserve cost and increase speed.
> - **Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model
> - **Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model
> - **Architecture, design, and review tasks**: use the most capable available model

**Task Complexity Signals:**
- Touches 1-2 files with complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

**Handling Implementer Status** (lines 102-118):
- **DONE:** Proceed to spec compliance review
- **DONE_WITH_CONCERNS:** Read concerns. If about correctness/scope, address before review. If observations, note and proceed.
- **NEEDS_CONTEXT:** Provide missing information and re-dispatch
- **BLOCKED:** Assess blocker:
  1. Context problem → provide context and re-dispatch (same model)
  2. Needs more reasoning → re-dispatch (more capable model)
  3. Task too large → break into smaller pieces
  4. Plan wrong → escalate to human
> **Never ignore an escalation or force the same model to retry without changes.**

**Prompt Templates** (lines 120-124):
- `./implementer-prompt.md` — Dispatch implementer subagent
- `./spec-reviewer-prompt.md` — Dispatch spec compliance reviewer
- `./code-quality-reviewer-prompt.md` — Dispatch code quality reviewer

**Example Workflow** (lines 126-200):
Detailed walk-through of 2-task execution with questions, self-review, spec review issues, code review issues, and approvals.

**Advantages** (lines 202-232):
- **vs. Manual execution:**
  - Subagents follow TDD naturally
  - Fresh context per task (no confusion)
  - Parallel-safe (no interference)
  - Subagent can ask questions (before AND during work)

- **vs. Executing Plans:**
  - Same session (no handoff)
  - Continuous progress (no waiting)
  - Review checkpoints automatic

- **Efficiency gains:**
  - No file reading overhead
  - Controller curates exactly what context is needed
  - Subagent gets complete information upfront
  - Questions surfaced before work begins

- **Quality gates:**
  - Self-review catches issues before handoff
  - Two-stage review: spec compliance, then code quality
  - Review loops ensure fixes actually work
  - Spec compliance prevents over/under-building
  - Code quality ensures implementation is well-built

- **Cost:** More subagent invocations, but catches issues early (cheaper than debugging later)

**Red Flags** (lines 234-260):
- Never start implementation on main/master branch without explicit user consent
- Skip reviews (either stage)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- Skip scene-setting context
- Ignore subagent questions (answer before proceeding)
- Accept "close enough" on spec compliance
- Skip review loops (reviewer found issues = not done)
- Let implementer self-review replace actual review
- **Start code quality review before spec compliance is ✅**
- Move to next task while either review has open issues

**Supporting Files:**
- `./implementer-prompt.md` (131 lines) — Instructions for implementation subagent
- `./spec-reviewer-prompt.md` (41 lines) — Instructions for spec compliance reviewer
- `./code-quality-reviewer-prompt.md` (43 lines) — Instructions for code quality reviewer

---

### 4.2 Dispatching Parallel Agents: `dispatching-parallel-agents` (Parallel Independent)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/dispatching-parallel-agents/SKILL.md`

**Frontmatter:**
- **Name:** `dispatching-parallel-agents`
- **Description:** "Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies"

**Core Principle** (lines 6-14):
> You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, 
> you ensure they stay focused and succeed at their task. They should never inherit your session's context or history.
>
> When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating 
> them sequentially wastes time. Each investigation is independent and can happen in parallel.

**When to Use** (lines 16-33, decision tree):
- Multiple failures? → Are they independent?
  - NO (related) → Single agent investigates all
  - YES → Can they work in parallel?
    - NO (shared state) → Sequential agents
    - YES → Parallel dispatch

**Use when:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**
- Failures are related (fix one might fix others)
- Need to understand full system state
- Agents would interfere with each other

**The Pattern** (lines 47-82):
1. **Identify Independent Domains**
   - Group failures by what's broken
   - Example: File A tests (Tool approval), File B tests (Batch completion), File C tests (Abort functionality)
   - Each domain independent — fixing one doesn't affect others

2. **Create Focused Agent Tasks**
   - Specific scope: One test file or subsystem
   - Clear goal: Make these tests pass
   - Constraints: Don't change other code
   - Expected output: Summary of what you found and fixed

3. **Dispatch in Parallel**
   - Task("Fix agent-tool-abort.test.ts failures")
   - Task("Fix batch-completion-behavior.test.ts failures")
   - Task("Fix tool-approval-race-conditions.test.ts failures")
   - All three run concurrently

4. **Review and Integrate**
   - Read each summary
   - Verify fixes don't conflict
   - Run full test suite
   - Integrate all changes

**Agent Prompt Structure** (lines 84-110):
Good agent prompts are:
1. **Focused** — One clear problem domain
2. **Self-contained** — All context needed
3. **Specific about output** — What should agent return?

Example given for fixing 3 failing tests in src/agents/agent-tool-abort.test.ts with timing/race condition issues.

**Common Mistakes** (lines 112-124):
- ❌ Too broad: "Fix all the tests" vs ✅ Specific: "Fix agent-tool-abort.test.ts"
- ❌ No context: "Fix the race condition" vs ✅ Context: Paste error messages and test names
- ❌ No constraints: Agent might refactor everything vs ✅ Constraints: "Do NOT change production code"
- ❌ Vague output: "Fix it" vs ✅ Specific: "Return summary of root cause and changes"

**When NOT to Use** (lines 126-130):
- Related failures (fix one might fix others)
- Need full context
- Exploratory debugging (don't know what's broken yet)
- Shared state (agents would interfere)

**Real Example** (lines 132-157):
6 test failures across 3 files after major refactoring → 3 independent agents dispatched in parallel → All solved concurrently, no conflicts.

**Key Benefits** (lines 159-166):
1. Parallelization
2. Focus (narrow scope)
3. Independence (no interference)
4. Speed (3 problems in time of 1)

**Verification** (lines 168-173):
After agents return:
1. Review each summary
2. Check for conflicts
3. Run full suite
4. Spot check (agents can make systematic errors)

---

## Part 5: Git and Code Review Skills

### 5.1 Using Git Worktrees: `using-git-worktrees` (Environment Setup)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/using-git-worktrees/SKILL.md`

**Frontmatter:**
- **Name:** `using-git-worktrees`
- **Description:** "Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification"

**Core Principle** (lines 6-14):
> Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches 
> simultaneously without switching.
> **Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

**Directory Selection Process** (lines 16-60, three-step priority):

**1. Check Existing Directories**
```bash
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```
If found: Use that directory. If both exist, `.worktrees` wins.

**2. Check CLAUDE.md**
```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```
If preference specified: Use it without asking.

**3. Ask User**
If no directory exists and no CLAUDE.md preference:
```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/.config/superpowers/worktrees/<project-name>/ (global location)

Which would you prefer?
```

**Safety Verification** (lines 52-74):

**For Project-Local Directories (.worktrees or worktrees)**
MUST verify directory is ignored before creating worktree:
```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If NOT ignored:
1. Add appropriate line to .gitignore
2. Commit the change
3. Proceed with worktree creation
> **Why critical:** Prevents accidentally committing worktree contents to repository.

**For Global Directory (~/.config/superpowers/worktrees)**
No .gitignore verification needed — outside project entirely.

**Creation Steps** (lines 76-141):

1. **Detect Project Name**
```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

2. **Create Worktree**
```bash
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/superpowers/worktrees/*)
    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

3. **Run Project Setup** (auto-detect and run):
- Node.js: `npm install`
- Rust: `cargo build`
- Python: `pip install -r requirements.txt` or `poetry install`
- Go: `go mod download`

4. **Verify Clean Baseline**
Run tests to ensure worktree starts clean:
- Node.js: `npm test`
- Rust: `cargo test`
- Python: `pytest`
- Go: `go test ./...`
> If tests fail: Report failures, ask whether to proceed or investigate.
> If tests pass: Report ready.

5. **Report Location**
```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

**Quick Reference Table** (lines 144-154):
| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → Ask user |
| Directory not ignored | Add to .gitignore + commit |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

**Common Mistakes** (lines 156-176):
- **Skipping ignore verification** → Worktree contents tracked, pollute git status → Always use `git check-ignore`
- **Assuming directory location** → Creates inconsistency → Follow priority: existing > CLAUDE.md > ask
- **Proceeding with failing tests** → Can't distinguish new bugs from pre-existing → Report failures, get permission
- **Hardcoding setup commands** → Breaks on projects with different tools → Auto-detect from project files

---

### 5.2 Requesting Code Review: `requesting-code-review` (Review Dispatch)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/requesting-code-review/SKILL.md`

**Frontmatter:**
- **Name:** `requesting-code-review`
- **Description:** "Use when completing tasks, implementing major features, or before merging to verify work meets requirements"

**Core Principle** (lines 6-10):
> Dispatch superpowers:code-reviewer subagent to catch issues before they cascade. 
> The reviewer gets precisely crafted context for evaluation — never your session's history. 
> This keeps the reviewer focused on the work product, not your thought process, and preserves 
> your own context for continued work.

**When to Request Review** (lines 12-22):
**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

**How to Request** (lines 24-43):
1. **Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

2. **Dispatch code-reviewer subagent:**
Use Task tool with superpowers:code-reviewer type, fill template at `code-reviewer.md`

**Placeholders:**
- `{WHAT_WAS_IMPLEMENTED}` — What you just built
- `{PLAN_OR_REQUIREMENTS}` — What it should do
- `{BASE_SHA}` — Starting commit
- `{HEAD_SHA}` — Ending commit
- `{DESCRIPTION}` — Brief summary

3. **Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

**Integration with Workflows** (lines 77-91):
- **Subagent-Driven Development:** Review after EACH task
- **Executing Plans:** Review after each batch (3 tasks)
- **Ad-Hoc Development:** Review before merge or when stuck

**Red Flags** (lines 92-99):
- Never skip review because "it's simple"
- Never ignore Critical issues
- Never proceed with unfixed Important issues
- Never argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

**Supporting File:** `./code-reviewer.md` — Template file

---

### 5.3 Receiving Code Review: `receiving-code-review` (Feedback Processing)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/receiving-code-review/SKILL.md`

**Frontmatter:**
- **Name:** `receiving-code-review`
- **Description:** "Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation"

**Core Principle** (lines 6-14):
> Code review requires technical evaluation, not emotional performance.
> **Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

**The Response Pattern** (lines 16-25):
```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

**Forbidden Responses** (lines 27-38):
**NEVER:**
- "You're absolutely right\!" (explicit CLAUDE.md violation)
- "Great point\!" / "Excellent feedback\!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

**Handling Unclear Feedback** (lines 40-57):
```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Source-Specific Handling** (lines 59-86):

**From your human partner:**
- **Trusted** — implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

**From External Reviewers:**
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning
```

**your human partner's rule:** "External feedback - be skeptical, but check carefully"

**YAGNI Check for "Professional" Features** (lines 88-99):
```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**Implementation Order** (lines 101-112):
```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

**When To Push Back** (lines 114-129):
Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve your human partner if architectural

**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"

**Acknowledging Correct Feedback** (lines 131-147):
When feedback IS correct:
```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right\!"
❌ "Great point\!"
❌ "Thanks for catching that\!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
```
> **Why no thanks:** Actions speak. Just fix it. The code itself shows you heard the feedback.

**Gracefully Correcting Your Pushback** (lines 150-162):
If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```
State the correction factually and move on.

**GitHub Thread Replies** (lines 203-205):
When replying to inline review comments on GitHub, reply in the comment thread 
(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

---

### 5.4 Finishing a Development Branch: `finishing-a-development-branch` (Merge/PR)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/finishing-a-development-branch/SKILL.md`

**Frontmatter:**
- **Name:** `finishing-a-development-branch`
- **Description:** "Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup"

**Core Principle** (lines 6-14):
> Guide completion of development work by presenting clear options and handling chosen workflow.
> **Core principle:** Verify tests → Present options → Execute choice → Clean up.
> **Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

**The Four-Step Process** (lines 16-151):

**Step 1: Verify Tests**
Before presenting options, verify tests pass:
```bash
npm test / cargo test / pytest / go test ./...
```

If tests fail:
```
Tests failing (<N> failures). Must fix before completing:
[Show failures]
Cannot proceed with merge/PR until tests pass.
```
Stop. Don't proceed to Step 2.

**Step 2: Determine Base Branch**
```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```
Or ask: "This branch split from main - is that correct?"

**Step 3: Present Options**
Present exactly these 4 options (no additions, no explanation):
```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Step 4: Execute Choice**

**Option 1: Merge Locally**
- Switch to base branch
- Pull latest
- Merge feature branch
- Verify tests on merged result
- If tests pass: delete feature branch
- Cleanup worktree (Step 5)

**Option 2: Push and Create PR**
- Push branch: `git push -u origin <feature-branch>`
- Create PR with gh command
- Cleanup worktree (Step 5)

**Option 3: Keep As-Is**
- Report: "Keeping branch <name>. Worktree preserved at <path>."
- Don't cleanup worktree

**Option 4: Discard**
- Confirm first: "This will permanently delete..."
- Wait for exact confirmation: user types 'discard'
- If confirmed: delete branch and cleanup worktree (Step 5)

**Step 5: Cleanup Worktree**
For Options 1, 2, 4:
- Check if in worktree: `git worktree list | grep $(git branch --show-current)`
- If yes: `git worktree remove <worktree-path>`

For Option 3: Keep worktree.

**Quick Reference Table** (lines 152-160):
| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

**Common Mistakes** (lines 162-176):
- **Skipping test verification** → Merge broken code → Always verify
- **Open-ended questions** → "What should I do next?" is ambiguous → Present 4 structured options
- **Automatic worktree cleanup** → Remove when might need it → Only cleanup for Options 1 & 4
- **No confirmation for discard** → Accidentally delete work → Require typed "discard"

**Red Flags** (lines 178-191):
- Never proceed with failing tests
- Never merge without verifying tests on result
- Never delete work without confirmation
- Never force-push without explicit request

---

## Part 6: Skill Creation Framework

### 6.1 Writing Skills: `writing-skills` (Meta-Documentation)

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/writing-skills/SKILL.md`

**Frontmatter:**
- **Name:** `writing-skills`
- **Description:** "Use when creating new skills, editing existing skills, or verifying skills work before deployment"

**Core Principle** (lines 6-23):
> **Writing skills IS Test-Driven Development applied to process documentation.**
> 
> You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), 
> write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).
> 
> **Core principle:** If you didn't watch an agent fail without the skill, you don't know if the 
> skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand `superpowers:test-driven-development` before using this skill.

**What is a Skill?** (lines 25-32):
> A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future Claude instances 
> find and apply effective approaches.
> 
> **Skills are:** Reusable techniques, patterns, tools, reference guides
> **Skills are NOT:** Narratives about how you solved a problem once

**TDD Mapping for Skills** (lines 34-45, table):
| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Production code** | Skill document (SKILL.md) |
| **Test fails (RED)** | Agent violates rule without skill (baseline) |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |
| **Write test first** | Run baseline scenario BEFORE writing skill |
| **Watch it fail** | Document exact rationalizations agent uses |
| **Minimal code** | Write skill addressing those specific violations |
| **Watch it pass** | Verify agent now complies |
| **Refactor cycle** | Find new rationalizations → plug → re-verify |

**When to Create a Skill** (lines 47-59):
**Create when:**
- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in CLAUDE.md)
- Mechanical constraints (if enforceable with regex/validation, automate it)

**Skill Types** (lines 61-68):
1. **Technique** — Concrete method with steps (condition-based-waiting, root-cause-tracing)
2. **Pattern** — Way of thinking (flatten-with-flags, test-invariants)
3. **Reference** — API docs, syntax guides, tool documentation

**Directory Structure** (lines 70-91):
```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```
- **Flat namespace** — all skills in one searchable namespace
- **Separate files for:**
  1. Heavy reference (100+ lines) — API docs, comprehensive syntax
  2. Reusable tools — Scripts, utilities, templates
- **Keep inline:**
  - Principles and concepts
  - Code patterns (< 50 lines)
  - Everything else

**SKILL.md Structure** (lines 93-138):
**Frontmatter (YAML):**
- Two required fields: `name` and `description`
- Max 1024 characters total
- `name`: Letters, numbers, and hyphens only (no parentheses, special chars)
- `description`: Third-person, describes ONLY when to use (NOT what it does)
  - Start with "Use when..." to focus on triggering conditions
  - Include specific symptoms, situations, and contexts
  - **NEVER summarize the skill's process or workflow** (CSO section explains why)
  - Keep under 500 characters if possible

**Suggested Sections:**
- Overview: What is this? Core principle in 1-2 sentences.
- When to Use: [Small inline flowchart IF decision non-obvious] + Bullet list with SYMPTOMS and use cases + When NOT to use
- Core Pattern (for techniques/patterns): Before/after code comparison
- Quick Reference: Table or bullets for scanning common operations
- Implementation: Inline code for simple patterns or link to file for heavy reference
- Common Mistakes: What goes wrong + fixes
- Real-World Impact (optional): Concrete results

**Claude Search Optimization (CSO)** (lines 140-197):

**Critical for discovery:** Future Claude needs to FIND your skill

**1. Rich Description Field**
- **Purpose:** Claude reads description to decide which skills to load. Make it answer: "Should I read this skill right now?"
- **Format:** Start with "Use when..." to focus on triggering conditions
- **CRITICAL: Description = When to Use, NOT What the Skill Does**

The description should ONLY describe triggering conditions. Do NOT summarize the skill's process or workflow.

**Why this matters:** Testing revealed that when a description summarizes the skill's workflow, Claude may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill's flowchart showed TWO.

When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), Claude correctly read the flowchart and followed the two-stage review process.

**The trap:** Descriptions that summarize workflow create a shortcut Claude will take. The skill body becomes documentation Claude skips.

Examples:
```yaml
# ❌ BAD: Summarizes workflow
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ❌ BAD: Too much process detail
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# ✅ GOOD: Just triggering conditions, no workflow summary
description: Use when executing implementation plans with independent tasks in the current session

# ✅ GOOD: Triggering conditions only
description: Use when implementing any feature or bugfix, before writing implementation code
```

**Content:**
- Use concrete triggers, symptoms, and situations
- Describe the **problem** (race conditions, inconsistent behavior) not **language-specific symptoms**
- Keep triggers technology-agnostic unless the skill itself is technology-specific
- Write in third person (injected into system prompt)
- **NEVER summarize the skill's process or workflow**

**2. Keyword Coverage**
Use words Claude would search for:
- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

**3. Descriptive Naming**
- Use active voice, verb-first
- ✅ `creating-skills` not `skill-creation`
- ✅ `condition-based-waiting` not `async-test-helpers`

**4. Token Efficiency (Critical)**
- **Problem:** getting-started and frequently-referenced skills load into EVERY conversation. Every token counts.
- **Target word counts:**
  - getting-started workflows: <150 words each
  - Frequently-loaded skills: <200 words total
  - Other skills: <500 words (still concise)

**Techniques:**
- Move details to tool help (reference `--help`)
- Use cross-references (reference other skill)
- Compress examples
- Eliminate redundancy

**Flowchart Usage** (lines 291-316):
```dot
digraph when_flowchart {
    "Need to show information?" [shape=diamond];
    "Decision where I might go wrong?" [shape=diamond];
    "Use markdown" [shape=box];
    "Small inline flowchart" [shape=box];
    ...
}
```

**Use flowcharts ONLY for:**
- Non-obvious decision points
- Process loops where you might stop too early
- "When to use A vs B" decisions

**Never use flowcharts for:**
- Reference material → Tables, lists
- Code examples → Markdown blocks
- Linear instructions → Numbered lists
- Labels without semantic meaning (step1, helper2)

**Style rules:** See `./graphviz-conventions.dot` (172 lines)
- Node shapes: diamond (decision), box (action), plaintext (command), ellipse (state), octagon (warning), doublecircle (entry/exit)
- Naming: Questions end with "?", Actions start with verb, Commands are literal, States describe situation
- Process template with decision trees, actions, verification checks

**Rendering for partner:** Use `render-graphs.js` in this directory:
```bash
./render-graphs.js ../some-skill           # Each diagram separately
./render-graphs.js ../some-skill --combine # All diagrams in one SVG
```

**Code Examples** (lines 324-346):
- **One excellent example beats many mediocre ones**
- Choose most relevant language: TypeScript/JavaScript for testing, Shell/Python for system debugging, Python for data processing
- **Good example:**
  - Complete and runnable
  - Well-commented explaining WHY
  - From real scenario
  - Shows pattern clearly
  - Ready to adapt (not generic template)
- **Don't:** Implement in 5+ languages, create fill-in-the-blank templates, write contrived examples

**File Organization** (lines 348-371):
- **Self-Contained Skill:** SKILL.md only (everything inline)
- **Skill with Reusable Tool:** SKILL.md + working helpers to adapt
- **Skill with Heavy Reference:** SKILL.md (overview + workflows) + supporting files (API docs, XML structure, scripts)

**The Iron Law** (lines 374-393):
```
NO SKILL WITHOUT A FAILING TEST FIRST

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing? Delete it. Start over.
Edit skill without testing? Same violation.

No exceptions:
- Not for "simple additions"
- Not for "just adding a section"
- Not for "documentation updates"
- Don't keep untested changes as "reference"
- Don't "adapt" while running tests
- Delete means delete

REQUIRED BACKGROUND: superpowers:test-driven-development explains why.
```

**Testing All Skill Types** (lines 395-442):

**Discipline-Enforcing Skills** (TDD, verification-before-completion, designing-before-coding)
- Test with: Academic questions, Pressure scenarios (time, sunk cost, authority, exhaustion), Multiple pressures combined, Identify rationalizations
- Success criteria: Agent follows rule under maximum pressure

**Technique Skills** (condition-based-waiting, root-cause-tracing, defensive-programming)
- Test with: Application scenarios, Variation scenarios, Missing information tests
- Success criteria: Agent successfully applies technique to new scenario

**Pattern Skills** (reducing-complexity, information-hiding)
- Test with: Recognition scenarios, Application scenarios, Counter-examples
- Success criteria: Agent correctly identifies when/how to apply pattern

**Reference Skills** (API documentation, command references)
- Test with: Retrieval scenarios, Application scenarios, Gap testing
- Success criteria: Agent finds and correctly applies reference information

**Common Rationalizations for Skipping Testing** (lines 444-457, table):
| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing less tedious than debugging bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

> All of these mean: Test before deploying. No exceptions.

**Bulletproofing Skills Against Rationalization** (lines 459-523):
Skills that enforce discipline need to resist rationalization. Agents are smart and find loopholes under pressure.

**Psychology note:** Understanding WHY persuasion techniques work helps you apply them systematically.
Reference: `./persuasion-principles.md` (research on Cialdini 2021; Meincke et al. 2025 on authority, commitment, scarcity, social proof, unity principles)

**Close Every Loophole Explicitly**
Don't just state the rule — forbid specific workarounds:
```markdown
# ❌ BAD
Write code before test? Delete it.

# ✅ GOOD
Write code before test? Delete it. Start over.

No exceptions:
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```

**Address "Spirit vs Letter" Arguments**
Add foundational principle early:
```markdown
Violating the letter of the rules is violating the spirit of the rules.
```
This cuts off entire class of "I'm following the spirit" rationalizations.

**Build Rationalization Table**
Capture rationalizations from baseline testing. Every excuse agents make goes in the table.

**Create Red Flags List**
Make it easy for agents to self-check when rationalizing:
```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**
```

**Update CSO for Violation Symptoms**
Add to description: symptoms of when you're ABOUT to violate the rule

**RED-GREEN-REFACTOR for Skills** (lines 533-554):
Follow the TDD cycle:

**RED: Write Failing Test (Baseline)**
Run pressure scenario with subagent WITHOUT the skill. Document exact behavior:
- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?
> This is "watch the test fail" — you must see what agents naturally do before writing skill.

**GREEN: Write Minimal Skill**
Write skill that addresses those specific rationalizations. Don't add extra content for hypothetical cases.
Run same scenarios WITH skill. Agent should now comply.

**REFACTOR: Close Loopholes**
Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

**Testing methodology:** See `@testing-skills-with-subagents.md` (209 lines) for complete testing methodology:
- How to write pressure scenarios
- Pressure types (time, sunk cost, authority, exhaustion)
- Plugging holes systematically
- Meta-testing techniques

**Anti-Patterns** (lines 562-581):
- ❌ Narrative Example: "In session 2025-10-03, we found..."
- ❌ Multi-Language Dilution: example-js.js, example-py.py, example-go.go
- ❌ Code in Flowcharts: Can't copy-paste, hard to read
- ❌ Generic Labels: helper1, helper2, step3, pattern4

**STOP: Before Moving to Next Skill** (lines 583-594):
**After writing ANY skill, you MUST STOP and complete the deployment process.**

**Do NOT:**
- Create multiple skills in batch without testing each
- Move to next skill before current one is verified
- Skip testing because "batching is more efficient"

> The deployment checklist below is MANDATORY for EACH skill.
> Deploying untested skills = deploying untested code.

**Skill Creation Checklist (TDD Adapted)** (lines 596-633):
**IMPORTANT: Use TodoWrite to create todos for EACH checklist item below.**

**RED Phase - Write Failing Test:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill — document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase - Write Minimal Skill:**
- [ ] Name uses only letters, numbers, hyphens (no parentheses/special chars)
- [ ] YAML frontmatter with required `name` and `description` fields (max 1024 chars)
- [ ] Description starts with "Use when..." and includes specific triggers/symptoms
- [ ] Description written in third person
- [ ] Keywords throughout for search (errors, symptoms, tools)
- [ ] Clear overview with core principle
- [ ] Address specific baseline failures identified in RED
- [ ] Code inline OR link to separate file
- [ ] One excellent example (not multi-language)
- [ ] Run scenarios WITH skill — verify agents now comply

**REFACTOR Phase - Close Loopholes:**
- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters (if discipline skill)
- [ ] Build rationalization table from all test iterations
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Quality Checks:**
- [ ] Small flowchart only if decision non-obvious
- [ ] Quick reference table
- [ ] Common mistakes section
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference

**Deployment:**
- [ ] Commit skill to git and push to your fork (if configured)
- [ ] Consider contributing back via PR (if broadly useful)

**Discovery Workflow** (lines 635-645):
How future Claude finds your skill:
1. **Encounters problem** ("tests are flaky")
2. **Finds SKILL** (description matches)
3. **Scans overview** (is this relevant?)
4. **Reads patterns** (quick reference table)
5. **Loads example** (only when implementing)

> **Optimize for this flow** — put searchable terms early and often.

**Supporting Files:**
- `./anthropic-best-practices.md` (1361 lines) — Official Anthropic skill authoring guidance
- `./testing-skills-with-subagents.md` (209 lines) — Complete testing methodology
- `./persuasion-principles.md` (188 lines) — Psychology-backed compliance techniques
- `./graphviz-conventions.dot` (172 lines) — Flowchart style guide
- `./render-graphs.js` — Utility to render Graphviz to SVG
- `./examples/` directory — Reference skill implementations

---

## Part 7: Cross-Skill Patterns and Architecture

### 7.1 Common Structural Pattern

**Frontmatter Format (YAML):**
All skills use consistent frontmatter:
```yaml
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions] - [specific symptoms/situations]
---
```

**Section Structure Across All Skills:**
1. **Frontmatter** (YAML metadata)
2. **Overview** (1-2 sentence core principle)
3. **When to Use** (symptoms, use cases, decision flowchart if complex)
4. **Core Process** (main workflow with detailed steps)
5. **Red Flags** (explicit prohibition on rationalizations)
6. **Common Rationalizations** (table matching excuse to reality)
7. **Real-World Example** (concrete scenario)
8. **Quick Reference** (table or bullets)

### 7.2 Graphviz Flowchart Conventions

**Used consistently across all skills for decision-making:**
- **Shapes:**
  - `doublecircle` — Process start/end points
  - `diamond` — Decision points ("Is X true?" questions)
  - `box` — Actions ("Do X")
  - `plaintext` — Commands (actual bash/shell code)
  - `ellipse` — States (current situation)
  - `octagon` (red fill) — STOP/critical warnings
  
- **Edge labels:**
  - Binary decisions: "yes" / "no" paths
  - Multiple choice: "condition A" / "condition B" / "otherwise"
  - Loop edges labeled with trigger

### 7.3 Red Flag Prevention Architecture

**Every rigid skill contains:**
1. **Iron Law** (single, non-negotiable principle)
2. **Hard Gate** (explicit blocker preventing continuation)
3. **Rationalization Prevention Table** (excuse → reality mapping)
4. **Red Flags Section** (symptoms of rationalization)
5. **"Violating the letter is violating the spirit" principle** (closes spirit-vs-letter arguments)

**Example from TDD:**
```
IRON LAW: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST

HARD GATE: If you haven't watched the test fail, you cannot proceed

RATIONALIZATION TABLE: [11 excuses with reality checks]

RED FLAGS: [Code before test, test passes immediately, "already manually tested", etc.]

PRINCIPLE: "Violating the letter of the rules is violating the spirit of the rules."
```

### 7.4 Persuasion Psychology Integration

**Reference:** `./writing-skills/persuasion-principles.md` (188 lines)

**Seven Principles Tested with N=28,000 conversations (Meincke et al., 2025):**

1. **Authority** — Imperative language, non-negotiable framing
   - **Used in:** TDD, Verification, Debugging (discipline skills)
   - **Examples:** "YOU MUST", "Never", "Always", "No exceptions"

2. **Commitment** — Require announcements, force explicit choices, use TodoWrite tracking
   - **Used in:** Using-superpowers, executing-plans, writing-plans
   - **Examples:** "Announce skill usage", "Create TodoWrite per item"

3. **Scarcity** — Time-bound requirements, sequential dependencies
   - **Used in:** Verification-before-completion, debugging phases
   - **Examples:** "Before proceeding", "Immediately after"

4. **Social Proof** — Universal patterns, failure modes, norms
   - **Used in:** TDD, Debugging, Code review
   - **Examples:** "Every time", "Always", "All of these mean..."

5. **Unity** — Shared identity, "we-ness", collaborative language
   - **Used in:** Receiving-code-review, subagent-driven-development
   - **Examples:** "We're colleagues", "Our codebase"

6. **Reciprocity** — (Rarely used, avoided)
   - Can feel manipulative

7. **Liking** — (NEVER used for compliance)
   - Conflicts with honest feedback culture
   - Creates sycophancy

**Research Citation:**
- **Cialdini (2021)** — Seven principles of persuasion (foundational)
- **Meincke et al. (2025)** — Tested 7 principles with N=28,000 LLM conversations, compliance increased 33% → 72% with techniques

### 7.5 Skill Composition and Dependencies

**Skill Call Graph:**

```
using-superpowers (ENTRY POINT)
├── brainstorming (REQUIRED for creative work)
│   └── writing-plans (REQUIRED after design approval)
│       ├── executing-plans (OPTION 1: inline execution)
│       │   └── finishing-a-development-branch
│       └── subagent-driven-development (OPTION 2: parallel execution)
│           ├── test-driven-development (used by subagents)
│           ├── requesting-code-review (after each task)
│           │   └── receiving-code-review (when feedback arrives)
│           └── finishing-a-development-branch
│
├── test-driven-development (REQUIRED before any implementation)
├── systematic-debugging (REQUIRED before any fixes)
├── verification-before-completion (REQUIRED before completion claims)
├── using-git-worktrees (REQUIRED before executing plans)
├── dispatching-parallel-agents (OPTIONAL: parallel investigations)
│
└── writing-skills (REQUIRED: create/edit/test skills)
    └── testing-skills-with-subagents (methodology)
```

**Skill Types by Rigidity:**
- **Rigid (follow exactly):** TDD, Debugging, Verification, Brainstorming (hard gate)
- **Flexible (adapt to context):** Using-superpowers, Code review, Plans, Worktrees, Parallel dispatch

---

## Part 8: Supporting Reference Materials

### 8.1 Tool Mapping for Cross-Platform Support

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/using-superpowers/references/`

**copilot-tools.md** (53 lines):
Maps Claude Code tool names to Copilot CLI equivalents
- `Read` → `view`
- `Write` → `create`
- `Edit` → `edit`
- `Bash` → `bash`
- `Grep` → `grep`
- `Glob` → `glob`
- `Skill` → `skill`
- `Task` → `task` (with agent_type parameter)
- `TodoWrite` → `sql` with built-in `todos` table
- Async shell sessions with `bash` `async: true`, `write_bash`, `read_bash`, `stop_bash`, `list_bash`
- Additional Copilot tools: `store_memory`, `report_intent`, `sql`, GitHub MCP tools

**codex-tools.md** (102 lines):
Maps Claude Code to Codex equivalents
- `Task` → `spawn_agent` (with multi_agent = true config)
- `TodoWrite` → `update_plan`
- Named agent dispatch workaround: read prompt file, fill template placeholders, spawn worker agent
- Environment detection for worktree/branch operations
- Codex App finishing workflow

**gemini-tools.md** (mentioned as supported)

### 8.2 Anthropic Best Practices

**Location:** `/Volumes/corsair-ex/bonsai-git/bonsaipowers/skills/writing-skills/anthropic-best-practices.md`
(1361 lines — too extensive to fully document here, but referenced in writing-skills skill)

### 8.3 Debugging Support Techniques

**root-cause-tracing.md** (165 lines):
- 5-step process: Observe symptom → Find immediate cause → Ask "What called this?" → Keep tracing up → Find original trigger
- Stack trace instrumentation with `console.error()` and `new Error().stack`
- Using `find-polluter.sh` bisection script for test pollution detection
- Multi-layer defense strategy after finding root cause
- Key principle: Never fix just the symptom, always trace to source

**condition-based-waiting.md** — Async testing technique
**defense-in-depth.md** — Multi-layer validation strategy
**find-polluter.sh** — Script to identify test pollution

---

## Part 9: Inventory Summary

### Skills Inventory (14 Primary Skills)

| # | Name | Type | Rigidity | Key Category |
|---|------|------|----------|--------------|
| 1 | `using-superpowers` | Meta/Foundation | Rigid | How to use skills |
| 2 | `brainstorming` | Process | Rigid | Before creative work |
| 3 | `test-driven-development` | Discipline | Rigid | Before implementation |
| 4 | `systematic-debugging` | Discipline | Rigid | Before fixes |
| 5 | `verification-before-completion` | Discipline | Rigid | Before completion claims |
| 6 | `writing-plans` | Specification | Flexible | Plan creation |
| 7 | `executing-plans` | Execution | Flexible | Sequential execution |
| 8 | `subagent-driven-development` | Execution | Flexible | Parallel execution |
| 9 | `dispatching-parallel-agents` | Execution | Flexible | Parallel independent tasks |
| 10 | `using-git-worktrees` | Environment | Flexible | Workspace isolation |
| 11 | `requesting-code-review` | Review | Flexible | Review dispatch |
| 12 | `receiving-code-review` | Review | Flexible | Review feedback processing |
| 13 | `finishing-a-development-branch` | Workflow | Flexible | Merge/PR/cleanup |
| 14 | `writing-skills` | Meta | Flexible | Skill creation/editing |

### Supporting Files Inventory

**brainstorming/**
- `spec-document-reviewer-prompt.md` — Spec review subagent template
- `visual-companion.md` — Browser-based visual tool guide
- `scripts/` directory — (not detailed in reads)

**systematic-debugging/**
- `CREATION-LOG.md` — Development history
- `condition-based-waiting.md` — Async waiting technique
- `condition-based-waiting-example.ts` — TypeScript implementation
- `defense-in-depth.md` — Multi-layer validation
- `find-polluter.sh` — Test pollution finder script
- `root-cause-tracing.md` — Backward tracing technique
- `test-academic.md` — Academic test scenario
- `test-pressure-*.md` — (3 files) Pressure scenario documentation

**test-driven-development/**
- `testing-anti-patterns.md` — Common test mistakes

**writing-plans/**
- `plan-document-reviewer-prompt.md` — Plan review template

**writing-skills/**
- `anthropic-best-practices.md` — Official guidelines (1361 lines)
- `persuasion-principles.md` — Psychology-backed compliance (188 lines)
- `graphviz-conventions.dot` — Flowchart style guide (172 lines)
- `testing-skills-with-subagents.md` — Testing methodology (209 lines)
- `render-graphs.js` — Graphviz → SVG converter
- `examples/` — Reference implementations

**subagent-driven-development/**
- `implementer-prompt.md` — Implementation subagent template
- `spec-reviewer-prompt.md` — Spec review template
- `code-quality-reviewer-prompt.md` — Code quality review template

**requesting-code-review/**
- `code-reviewer.md` — Review dispatch template

**using-superpowers/references/**
- `copilot-tools.md` — Copilot CLI tool mapping
- `codex-tools.md` — Codex tool mapping
- `gemini-tools.md` — Gemini tool mapping

---

## Part 10: Key Insights and Takeaways

### 10.1 Foundational Thesis

The Bonsai superpowers system is **TDD applied to agent behavior change**. Each skill:
1. **Identifies behavior to change** (agents skipping brainstorming, rationalizating TDD, etc.)
2. **Runs baseline scenario** (RED phase) — documents exact rationalizations agents use
3. **Writes minimal skill documentation** (GREEN phase) — addresses only those identified issues
4. **Tests and refactors** (REFACTOR phase) — closes loopholes and re-tests until bulletproof

### 10.2 Persuasion Psychology Foundation

All skills leverage seven empirically-tested persuasion principles (Meincke et al., 2025, N=28,000):
- **Authority** (imperative, non-negotiable framing) — Most effective
- **Commitment** (announcements, forced choices, tracking) — Most effective
- **Scarcity** (time-bound, sequential) — Most effective
- **Social proof** (universal patterns, norms) — Supporting
- **Unity** (shared identity, collaboration) — Supporting
- **Reciprocity & Liking** — Avoided (manipulative or conflicts with honesty)

### 10.3 Rationalization Blocking Architecture

Every rigid skill uses multi-layered prevention:
1. **Iron Law** — Non-negotiable principle
2. **Hard Gate** — Explicit blocker at key decision point
3. **Rationalization Table** — Excuse → Reality mapping (15-30 pairs)
4. **Red Flags Section** — Self-check symptom list
5. **Spirit vs Letter Principle** — Closes meta-rationalization
6. **Testing with Pressure Scenarios** — Finds new loopholes

### 10.4 Tool-Agnostic Design

Skills use Claude Code tool names with explicit mappings to:
- **Copilot CLI** (`copilot-tools.md`)
- **Codex** (`codex-tools.md`)
- **Gemini** (auto-loaded in GEMINI.md)

No skill is tied to a single platform.

### 10.5 Workflow Orchestration Pattern

Skills compose into larger workflows:
1. **Entry:** `using-superpowers` (mandatory meta-skill)
2. **Design:** `brainstorming` (hard gate prevents premature implementation)
3. **Planning:** `writing-plans` (creates detailed task list)
4. **Execution:** Choose one of:
   - **Sequential (same session):** `executing-plans`
   - **Parallel (same session):** `subagent-driven-development`
5. **Completion:** `finishing-a-development-branch` (structured options)

Each step is a gate; each skill is mandatory when conditions match.

### 10.6 Code Review as Bidirectional Process

Code review is treated as TWO separate skills:
- **`requesting-code-review`** — How to dispatch review (when, how to request)
- **`receiving-code-review`** — How to process feedback (verify, evaluate, push back technically)

This prevents "performative agreement" and emphasizes technical evaluation over emotional compliance.

### 10.7 Subagent Delegation Model

Three execution skills serve different scenarios:
- **`subagent-driven-development`** — Same session, fresh subagent per task, two-stage review (spec then code)
- **`executing-plans`** — Parallel session, inline execution, batch review checkpoints
- **`dispatching-parallel-agents`** — Multiple independent problem domains, concurrent investigation

Each preserves controller context while delegating specialized work.

---

## Final Notes

This research document represents an exhaustive inventory of the Bonsai superpowers skills system as of 2026-04-10. The system is:

- **Mature and comprehensive** — 14 primary skills + 20+ supporting files
- **Psychologically grounded** — Uses empirically-tested persuasion principles
- **Practically tested** — Each skill has red flags, rationalization tables, real-world examples
- **Cross-platform** — Tool mappings for Claude Code, Copilot CLI, Codex, Gemini
- **Rigorously self-documenting** — Writing-skills skill uses TDD to verify skill quality

The architecture emphasizes:
1. **Discipline enforcement** (TDD, Debugging, Verification are RIGID)
2. **Tool independence** (skills work on any platform via tool mapping)
3. **Workflow composition** (skills orchestrate into larger processes)
4. **Psychological resilience** (explicit loophole closure, rationalization prevention)
5. **Quality gates** (mandatory reviews, verification checkpoints, skill testing)

---

**Research completed:** 2026-04-10  
**Total skills analyzed:** 14 primary + supporting files  
**Total lines of SKILL.md content analyzed:** ~15,000+  
**Graphviz flowcharts:** 20+  
**Supporting techniques:** 10+  
**Persuasion principles:** 7 (empirically tested)
