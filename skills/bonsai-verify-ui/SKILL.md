---
name: bonsai-verify-ui
description: Use when runtime-verifying a web UI in a fresh /clear'ed session after subagent-driven-development completes on a feature branch, or when the user says "verify work", "verify this branch", "runtime test the UI", "verify UI". Do NOT use for backend-only changes, static verification, or when a dev server + Chrome DevTools MCP aren't available.
---

# bonsai-verify-ui

Runtime UI verification for work completed by `superpowers:subagent-driven-development`. Runs
in a fresh `/clear`ed session, reads spec + plan + git diff from disk, spawns a sonnet subagent
to generate a YAML test plan, executes the plan via Chrome DevTools MCP in the main context,
diagnoses failures via parallel sonnet subagents, and writes a report to
`docs/superpowers/verify/`.

**Core principle:** fresh session + disk-only inputs + main-context browser control = verification
that is independent of whatever the implementer believed they built. The browser must be driven
by exactly one agent (the main orchestrator) to avoid parallel-agent contention documented in
Chrome's 2026 multi-agent guidance.

**No auto-fix.** Verification exposes problems and diagnoses root causes. The human decides the
next step (debug manually, re-dispatch to a fix pass, revert).

## When to Use

- After `superpowers:subagent-driven-development` completes its final code reviewer pass and
  the user `/clear`s the session, before `superpowers:finishing-a-development-branch`
- User says "verify work", "verify this branch", "runtime test the UI", "verify UI"
- The feature branch has a web UI that can be opened in Chrome

**When NOT to use:**
- Backend-only changes with no user-observable UI
- Pure refactors with no behavior change
- Docs-only or config-only edits
- Static verification (typecheck, lint, tests) — those ran during subagent-driven-development
- When the dev server isn't running or Chrome DevTools MCP isn't configured

## Skill References

- `test-planner-agent.md` — protocol for the sonnet test-planner subagent
- `chrome-devtools-execution-patterns.md` — assertion-type → MCP tool lookup table

Both files are read at runtime:
- `test-planner-agent.md` is passed to the sonnet subagent via `<files_to_read>` in Phase 2
- `chrome-devtools-execution-patterns.md` is read by the main orchestrator in Phase 3

## The Process

```dot
digraph process {
    rankdir=TB;

    "Phase 1: Init & context discovery\n(main context, disk only)" [shape=box style=filled fillcolor=lightyellow];
    "Chrome connected?" [shape=diamond];
    "Stop + instructions" [shape=box];
    "Phase 2: Test plan generation\n(sonnet subagent, Task tool)" [shape=box];
    "Valid YAML?" [shape=diamond];
    "Retry or abort" [shape=diamond];
    "Abort: report to user" [shape=doublecircle];
    "Phase 3: Test execution\n(main context, chrome-devtools MCP)" [shape=box];
    "Any FAIL?" [shape=diamond];
    "Phase 4a: Diagnose failures\n(parallel sonnet subagents)" [shape=box];
    "Phase 4b: Write report, commit" [shape=box];
    "Present results + next step" [shape=doublecircle];

    "Phase 1: Init & context discovery\n(main context, disk only)" -> "Chrome connected?";
    "Chrome connected?" -> "Stop + instructions" [label="no"];
    "Chrome connected?" -> "Phase 2: Test plan generation\n(sonnet subagent, Task tool)" [label="yes"];
    "Phase 2: Test plan generation\n(sonnet subagent, Task tool)" -> "Valid YAML?";
    "Valid YAML?" -> "Retry or abort" [label="no"];
    "Retry or abort" -> "Phase 2: Test plan generation\n(sonnet subagent, Task tool)" [label="retry < 2"];
    "Retry or abort" -> "Abort: report to user" [label="retries exhausted"];
    "Valid YAML?" -> "Phase 3: Test execution\n(main context, chrome-devtools MCP)" [label="yes"];
    "Phase 3: Test execution\n(main context, chrome-devtools MCP)" -> "Any FAIL?";
    "Any FAIL?" -> "Phase 4a: Diagnose failures\n(parallel sonnet subagents)" [label="yes"];
    "Phase 4a: Diagnose failures\n(parallel sonnet subagents)" -> "Phase 4b: Write report, commit";
    "Any FAIL?" -> "Phase 4b: Write report, commit" [label="no"];
    "Phase 4b: Write report, commit" -> "Present results + next step";
}
```

## Phase 1: Init & Context Discovery

Runs entirely in the main orchestrator context using Bash, Read, Grep, Glob, and
`mcp__chrome-devtools__list_pages`.

1. **Branch check.** Run `git branch --show-current`. If the result is `main` or `master`, stop
   and tell the user to run the skill from the feature branch the implementation landed on.
   Never verify on the main branch.

2. **Commit range.** Run `git log main..HEAD --name-only --pretty=format:'%H%n%s%n%b%n---'`.
   Parse into `{sha, subject, body, files[]}` records.

3. **Plan/spec grep.** Across all commit subjects and bodies, regex-match
   `docs/superpowers/plans/[^ ]+\.md` and `docs/superpowers/specs/[^ ]+-design\.md`. Collect
   unique matches.

4. **Resolve ambiguity.**
   - Zero matches → fall back to "ask mode"
   - Exactly one match of each → proceed with those paths
   - Multiple matches → fall back to "ask mode"

5. **Ask fallback (only if needed).** Use `AskUserQuestion`. Build candidates:
   - `Glob('docs/superpowers/plans/*.md')` sorted by mtime descending, top 5
   - `Glob('docs/superpowers/specs/*-design.md')` sorted by mtime descending, top 5
   Present as a single multi-choice question with `{spec_path, plan_path}` pairs. User picks one.

6. **Read artifacts into context:**
   - Read the full text of `{spec_path}` and `{plan_path}`
   - Read `./CLAUDE.md` if it exists
   - Run `git diff main...HEAD --stat` and parse the file list

7. **Base URL detection.** Scan the plan body and `CLAUDE.md` for `localhost:\d+` patterns. Take
   the most frequent match. Default to `http://localhost:3000` if none found. Print one line
   to the user: `"Detected base URL: {url}. Press enter to accept or type a different URL."`
   Wait for the response and use whatever the user says.

8. **Chrome connection precheck.** Call `mcp__chrome-devtools__list_pages`:
   - **Pages returned, one matches `base_url`** → call `mcp__chrome-devtools__select_page` with
     that page's id
   - **Pages returned, none match** → call `mcp__chrome-devtools__new_page` with `url=base_url`
   - **Empty list or MCP error** → stop execution and print:
     ```
     Chrome DevTools MCP not connected. To proceed:
       1. Start your dev server (npm run dev / pnpm dev)
       2. Start Chrome with: chrome --remote-debugging-port=9222
       3. Re-run this skill in this same session
     ```
     Do not proceed without a connection.

**Output of Phase 1:** in-memory context object:
```
{ branch, spec_path, plan_path, changed_files, commit_range, base_url,
  connected_page_id }
```

Nothing is written to disk in Phase 1.

## Phase 2: Test Plan Generation

Spawn one sonnet subagent via the `Task` tool. The subagent reads the test planner protocol,
the spec, the plan, and `CLAUDE.md`, explores the source tree for changed files, and returns
a `<test_plan>` YAML block. The subagent has no chrome-devtools access — it only reads files
and returns YAML.

**Dispatch prompt:**

```
Task tool (general-purpose):
  description: "Generate runtime test plan for bonsai-verify-ui"
  model: sonnet
  prompt: |
    <objective>
    Explore what was built on branch {branch} and generate a <test_plan> YAML block for
    Chrome DevTools runtime testing. Return ONLY the YAML block, no prose.
    </objective>

    <agent_instructions>
    Read and follow the test planner protocol:
    skills/bonsai-verify-ui/test-planner-agent.md
    </agent_instructions>

    <context>
    Branch: {branch}
    Spec:   {spec_path}
    Plan:   {plan_path}
    Base URL: {base_url}
    Changed files (from git diff):
      {list of paths, one per line}
    </context>

    <files_to_read>
    - skills/bonsai-verify-ui/test-planner-agent.md
    - {spec_path}
    - {plan_path}
    - ./CLAUDE.md  (skip if not present)
    </files_to_read>
```

**Parse and validate the returned `<test_plan>` block.** Reject with retry if:

- The YAML is syntactically invalid
- Any test is missing `id`, `name`, `url`, `requires_auth`, or `assertions`
- Any assertion is missing `type` or `expected`
- Any URL contains `http://` or `https://` (must be relative)
- Any selector uses `nth-child`, XPath, or CSS-module hash patterns
- Any file in `<context>.changed_files` is absent from both `tests[].url`/selector references
  and `untestable_files`

On retry (max 2), re-dispatch the subagent with an appended note explaining what failed. After
two retries, warn the user and offer: `proceed with partial plan`, `switch to interactive mode
where user describes tests`, `abort`.

## Phase 3: Test Execution

Main context runs the test plan. Deterministic loop over tests, no model calls, no subagents.
All tool calls are `mcp__chrome-devtools__*`.

**Read `chrome-devtools-execution-patterns.md` at the start of this phase** — it is
the lookup table for everything this phase does.

**Per-test flow:**

1. **Dependency skip** — if any `depends_on` id has status FAIL, mark this test SKIP
2. **Auth setup if needed** — if `test.requires_auth: true` AND auth setup has not yet run AND
   `auth.required: true` in the plan, run the auth setup sequence from
   `chrome-devtools-execution-patterns.md § Auth Setup`. If auth setup fails, mark this test
   and all subsequent auth-required tests SKIP with reason `"auth setup failed"`.
3. **Navigate** — `mcp__chrome-devtools__navigate_page(base_url + test.url)`
4. **Wait** — `mcp__chrome-devtools__wait_for(test.wait_for)` with 5s timeout, or 2s pause if
   `wait_for` is null
5. **Setup actions** — for each action in `test.setup_actions`, call the matching
   `mcp__chrome-devtools__*` tool from the Setup Action Mapping table. 500ms pause after each.
6. **Assertions** — for each assertion, use the Assertion Type Mapping table to call the right
   tool and evaluate the result
7. **Evidence** — `mcp__chrome-devtools__take_screenshot`. On FAIL, also
   `list_console_messages` + `list_network_requests`.
8. **Record** — append to `TEST_RESULTS` array with `{id, name, url, status, assertions,
   evidence_uri, console_errors?, failed_requests?}`
9. **Progress** — print one line to the user: `Test {i}/{N}: {name} — {PASS|FAIL|SKIP}`

**Error recovery** is defined in `chrome-devtools-execution-patterns.md § Error Recovery`. Key
rules:
- MCP tool failure → wait 2s, retry once, then mark FAIL and continue
- 3 consecutive test FAILs → stop execution, mark rest SKIPPED, proceed to Phase 4
- Navigation timeout → mark FAIL, continue
- Selector not found → take snapshot as evidence, mark assertion FAIL, continue

**Console noise filter** is defined in `chrome-devtools-execution-patterns.md § Console
Message Filtering`. Never ignore hydration warnings, `console.error` from app code, or failed
`fetch` responses.

## Phase 4: Report & Failure Diagnosis

### 4a. Diagnose failures (only if any test FAILED)

For each FAIL test, dispatch a sonnet subagent **in parallel** via a single message with
multiple `Task` calls. Parallel dispatch is required — N failing tests must not serialize.

**Diagnosis subagent prompt:**

```
Task tool (general-purpose):
  description: "Diagnose failure: {test.name}"
  model: sonnet
  prompt: |
    Diagnose the root cause of this test failure. You must NOT implement the fix — only
    identify what's wrong and where. Return exactly these fields as YAML:

      root_cause: one concise sentence
      affected_files:
        - path: file.ts
          line: 42
      suggested_fix: one concise sentence describing the human fix approach

    Test: {test.name}
    URL: {test.url}
    Expected: {test.expected}
    Failed assertions: {details}
    Console errors: {list}
    Failed network requests: {list}

    Context:
    - Spec: {spec_path}
    - Plan: {plan_path}
    - Changed files on this branch: {list}

    Start by reading the spec and plan to understand intent, then read the changed files
    referenced in the failure to identify the root cause.
```

Merge each subagent's return values into the corresponding test entry. If a diagnosis subagent
returns unstructured output, record `root_cause: "diagnosis failed, see raw output"` and save
the raw response — do not block the report on a bad diagnosis.

### 4b. Write report

**Report path:** `docs/superpowers/verify/YYYY-MM-DD-<topic>-verify.md`

**Topic derivation:**
1. Take the plan basename without `.md` (e.g., `2026-04-15-user-auth`)
2. Strip any leading `YYYY-MM-DD-` date prefix (e.g., `user-auth`)
3. That's the topic

Create the `docs/superpowers/verify/` directory if it doesn't exist.

**Report structure:**

```markdown
---
status: complete
branch: {branch}
spec: {spec_path}
plan: {plan_path}
started: {ISO timestamp of Phase 1 start}
updated: {ISO timestamp now}
---

## Summary

total: {N}  passed: {N}  failed: {N}  skipped: {N}

## Coverage

changed_files: {count from git diff}
covered_files: {count}
untestable_files:
  - path: {path}
    reason: {reason}

## Tests

### 1. {Test Name}
- **url:** {url}
- **expected:** {description}
- **result:** pass
- **evidence:** Screenshot resource URI from take_screenshot

### 2. {Failing Test Name}
- **url:** {url}
- **expected:** {description}
- **result:** fail
- **failed_assertions:**
  - type: {type}
    selector: {selector}
    expected: {expected}
    actual: {actual}
- **console_errors:**
  - {each error on its own line}
- **failed_requests:**
  - {method} {url} → {status} {message}
- **evidence:** Screenshot resource URI
- **root_cause:** {from diagnosis subagent}
- **affected_files:**
  - {path}:{line}
- **suggested_fix:** {one-line approach}

### 3. {Skipped Test Name}

- **url:** {test url}
- **expected:** {description}
- **result:** skipped
- **reason:** {why — e.g., "depends on test #N which failed", "auth setup failed", "stopped after 3 consecutive failures"}
```

### 4c. Commit the report

```bash
git add docs/superpowers/verify/{report_file}.md
git commit -m "verify: runtime UI verification for {topic}"
```

Do not skip hooks. Do not amend. Do not force-push.

### 4d. Present to user

Print a concise table:

```
## Verification Complete — {topic}

Runtime tests: {passed}/{total} passed

| # | Test | Result | Details |
|---|------|--------|---------|
| 1 | {name} | PASS | — |
| 2 | {name} | FAIL | {root cause} |
| 3 | {name} | SKIP | depends on #2 |

Report: docs/superpowers/verify/{file}.md
```

**All pass:**
```
✅ All tests passed. Ready to finish the branch.

Next: invoke superpowers:finishing-a-development-branch
```

**Any fail:**
```
⚠ {N} test(s) failed. Root causes diagnosed in the report.

Next steps (your choice):
- /clear + superpowers:systematic-debugging — dig into a specific failure
- /clear + superpowers:subagent-driven-development — hand the report to a fix pass
- Read the report and fix manually
```

## Red Flags

**Never:**
- Run this skill from `main` or `master` branch
- Proceed if Chrome DevTools MCP is not connected
- Dispatch multiple subagents that all need chrome-devtools access (only the main orchestrator
  drives the browser)
- Auto-fix failures (the skill diagnoses, the human decides)
- Amend or force-push the report commit
- Ignore hydration warnings or `console.error` from app code in the noise filter
- Skip the coverage audit — every changed file must be covered or justifiably untestable

## Integration

**Upstream:**
- `superpowers:subagent-driven-development` — implementation flow that hands off to this skill
  via an optional "Optional Runtime Verification" section after its final code reviewer approves

**Downstream:**
- `superpowers:finishing-a-development-branch` — next step after all tests pass
- `superpowers:systematic-debugging` — next step for investigating a specific failure
- `superpowers:subagent-driven-development` — rerun in a fix pass if the diagnosis surfaces
  fix-plan-worthy work
