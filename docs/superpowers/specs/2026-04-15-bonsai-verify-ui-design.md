# Design — `bonsai-verify-ui`: optional runtime UI verification after implementation

**Date:** 2026-04-15
**Author:** nick (via bonsaipowers brainstorming)
**Status:** approved for planning

---

## Problem

`skills/subagent-driven-development/SKILL.md` (Tier 2, Bonsai-edited) runs a tight per-task loop: implementer → spec reviewer → code quality reviewer → final code reviewer → hand off to `finishing-a-development-branch`. Every quality gate in that loop is static: tests, code review, spec compliance checks. None of them actually open a browser.

For UI work, static gates are necessary but not sufficient. A reviewer can approve code that lints, typechecks, has passing unit tests, matches the spec, and still produces a broken experience in a real browser — missing wiring, unhandled loading states, CORS errors, misconfigured routes, silent API failures, hydration mismatches. The team has seen this pattern repeatedly: "all green locally, broken on first manual test."

The upstream `gsdn-verify-work` skill (personal scope, not in this plugin) solves the equivalent problem for the GSD workflow by driving Chrome DevTools MCP from an orchestrator, spawning a sonnet subagent to generate a YAML test plan, and executing that plan against a live dev server. That pattern is proven in practice. We want the same capability hooked into the subagent-driven-development flow, but without the GSD phase-specific coupling (SUMMARY files, gsd-tools CLI, must_haves frontmatter) that exists in gsdn-verify-work.

The verification must run in a **fresh `/clear`ed session**. Two reasons: (1) context pollution from the implementation flow biases the verifier toward what the implementer *believed* they built, rather than what actually landed on disk; (2) by the time verification runs, the implementation session's context window is typically near its limit, and `/clear` is the pragmatic reset. This constraint means the verification logic must load all its inputs from disk — it cannot rely on anything the prior session had in memory.

## Goals

1. A runtime UI verifier that drives Chrome DevTools MCP and reports pass/fail with evidence and diagnosed root causes.
2. Operates in a fresh `/clear`ed session with zero inherited context. All inputs loaded from disk: spec, plan, `CLAUDE.md`, `git log`, `git diff`.
3. Discoverable from the natural handoff point at the end of `subagent-driven-development` — the user should not have to remember the skill exists.
4. Optional, skippable for non-UI work. No ceremony tax on backend-only or config-only tasks.
5. Comprehensive coverage: tests the full surface area of the change (every changed page/component/form), including happy paths, edge cases, validation failures, empty states, auth boundaries, and error states. Not a smoke test — an exhaustive runtime pass.
6. No auto-fix. Verification exposes problems; humans decide the next step. Diagnosis is fine — mutation is not.
7. Minimal Tier 2 merge-conflict surface. The verifier lives as a standalone Tier 3 skill; the Tier 2 footprint is a single optional section + flowchart node + integration line in `subagent-driven-development`.

## Non-goals

- Static code verification (typecheck, lint, unit tests). The per-task loop in subagent-driven-development already runs those; duplicating them blurs the skill's purpose.
- Automated fix planning or execution. Gap-closure, auto-plans, and re-dispatch to implementers all belong downstream — verification stops at "here's what's broken and why."
- Test framework integration (Playwright, Cypress, Vitest). The point is to drive the browser directly via MCP, not generate or maintain a test suite file on disk.
- GSD phase concepts. No SUMMARY files, no phase directories, no `must_haves` YAML field, no gsd-tools CLI. This skill only knows about spec files, plan files, and git state.
- Cross-browser testing. Chrome only. The MCP is chrome-specific and the team deploys against Chromium-based targets.

## Non-requirements confirmed by brainstorming

These were settled during the clarifying-question phase and are called out explicitly so they don't get re-debated during planning:

- **Runtime only, not static + runtime.** Chosen deliberately over a hybrid approach. If a team member wants typecheck + lint + tests, they run them themselves before `/clear`ing. (Q4: A)
- **Diagnose failures, don't auto-fix.** The skill spawns parallel sonnet debug agents on failures, merges their root-cause analyses into the report, then stops. (Q5: B)
- **Git-driven discovery with ask-fallback.** The skill detects the plan/spec from commits on the current branch; only asks the user if detection is ambiguous. (Q3: D)
- **Source of truth: spec + plan + git diff.** The sonnet test planner synthesizes test scenarios from all three, not from a dedicated `must_haves` field. No Tier 2 edit to `writing-plans` needed. (Q2: C)
- **Inserted after final code reviewer, before finishing-a-development-branch.** The verify step is downstream of every existing quality gate, not a replacement for any of them. (Q1: C)

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  Fresh /clear'ed session                                             │
│                                                                      │
│  User invokes bonsai-verify-ui (or skill auto-triggers on "verify    │
│  work", "runtime test", etc.)                                        │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Phase 1: Init & Context Discovery (main context)               │  │
│  │   - git branch, git log, git diff                              │  │
│  │   - Locate spec + plan (grep commit msgs; ask on fallback)     │  │
│  │   - Read spec, plan, CLAUDE.md                                 │  │
│  │   - Detect base URL                                            │  │
│  │   - Chrome connection precheck                                 │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Phase 2: Test Plan Generation (sonnet subagent via Task tool)  │  │
│  │   - Reads spec, plan, CLAUDE.md, changed source files          │  │
│  │   - Derives scenarios covering every changed surface           │  │
│  │   - Mandatory edge-case coverage (validation, empty, auth,     │  │
│  │     error states)                                              │  │
│  │   - Returns <test_plan> YAML block (no prose)                  │  │
│  │   - No chrome-devtools access                                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Phase 3: Test Execution (main context, chrome-devtools MCP)    │  │
│  │   - Deterministic loop over test plan                          │  │
│  │   - navigate → wait → setup actions → assertions → evidence    │  │
│  │   - Error recovery, dependency skip, progress reporting        │  │
│  │   - No model calls inside this phase                           │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Phase 4: Report & Failure Diagnosis                            │  │
│  │   - Write docs/superpowers/verify/{date}-{topic}-verify.md     │  │
│  │   - If any FAIL: parallel sonnet debug subagents diagnose      │  │
│  │     each failing test, root cause + affected files merged      │  │
│  │     into report                                                │  │
│  │   - Commit the report                                          │  │
│  │   - Present pass/fail table to user; offer next step           │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

**Runtime split:**

- **Main context (orchestrator)** runs all Chrome DevTools MCP tools. The browser is driven by exactly one agent to avoid the parallel-agent contention problem documented in Chrome's 2026 guidance on multi-agent browser workflows.
- **Sonnet subagent (test planner)** runs once, reads files, returns a YAML block. No browser.
- **Sonnet subagents (failure diagnosers)** run only when tests fail. One per failing test, dispatched in parallel via a single message with multiple `Task` calls. No browser.

---

## Phase 1 — Init & Context Discovery

Runs entirely in the orchestrator's main context using Bash, Read, Grep, Glob, and `mcp__chrome-devtools__list_pages`.

**Sequence:**

1. **Branch check.** Run `git branch --show-current`. If the result is `main` or `master`, stop immediately and tell the user to run the skill from the feature branch the implementation landed on. Verifying main/master makes no sense and would almost certainly match the wrong plan.
2. **Commit range.** Run `git log main..HEAD --name-only --pretty=format:'%H%n%s%n%b%n---'`. Parse into a list of `{sha, subject, body, files[]}` records. This is the "what happened on this branch" snapshot.
3. **Plan/spec grep.** Across all commit subjects and bodies, regex for `docs/superpowers/plans/*.md` and `docs/superpowers/specs/*-design.md`. Collect unique matches.
4. **Resolve ambiguity.**
   - Zero matches → fall back to "ask" mode.
   - One match of each → proceed with those paths.
   - Multiple matches → fall back to "ask" mode.
5. **Ask fallback (only if needed).** Use the `AskUserQuestion` tool. Build candidate lists:
   - `Glob('docs/superpowers/plans/*.md')` sorted by mtime descending, top 5
   - `Glob('docs/superpowers/specs/*-design.md')` sorted by mtime descending, top 5
   Present as a single multi-choice question: "Which spec and plan should I verify?" with pairs of `{spec_path, plan_path}`. The user picks one.
6. **Read artifacts.** Read the full text of:
   - `{spec_path}` — design intent
   - `{plan_path}` — what was built, tech stack, task list, required skills
   - `./CLAUDE.md` if it exists — project conventions, test URLs, credentials hints
   - `git diff main...HEAD --stat` — file-level change summary, used to define the coverage universe
7. **Base URL detection.** Scan the plan body and `CLAUDE.md` for `localhost:\d+` patterns. Take the most frequently occurring. If none found, default to `http://localhost:3000`. Present the detected URL to the user once, explicitly, so they can correct it in-line before execution starts. (This is a one-line confirmation, not a formal question — "Detected base URL: X. Press enter to accept or type a different URL.")
8. **Chrome connection precheck.** Call `mcp__chrome-devtools__list_pages`. Three possible outcomes:
   - **Pages returned, one matches base URL** → select it via `mcp__chrome-devtools__select_page`, proceed.
   - **Pages returned, none match base URL** → call `mcp__chrome-devtools__new_page(url=base_url)`, proceed.
   - **Empty list or MCP error** → print instructions and stop:
     ```
     Chrome DevTools MCP not connected. To proceed:
       1. Start your dev server (npm run dev / pnpm dev / whatever)
       2. Start Chrome with: chrome --remote-debugging-port=9222
       3. Re-run the skill in this same session
     ```
     Do not proceed without a connection. A "static-only" fallback mode is explicitly out of scope per the non-goal on static verification.

**Output of Phase 1:** an in-memory context object held by the orchestrator:

```
{
  branch,
  spec_path,
  plan_path,
  changed_files: [...],
  commit_range: [...],
  base_url,
  connected_page_id,
  auth_hint: {credentials_found, email_env_var, password_env_var} | null
}
```

Nothing is written to disk in Phase 1.

---

## Phase 2 — Test Plan Generation

A single sonnet subagent via the `Task` tool. The subagent explores what was built and returns a `<test_plan>` YAML block — nothing else.

**Dispatch prompt structure:**

```
<objective>
Explore what was built on branch {branch} and generate a <test_plan> YAML block
for Chrome DevTools runtime testing. Return ONLY the YAML block, no prose.
</objective>

<agent_instructions>
Read and follow the test planner protocol:
skills/bonsai-verify-ui/references/test-planner-agent.md
</agent_instructions>

<context>
Branch: {branch}
Spec:   {spec_path}
Plan:   {plan_path}
Base URL: {base_url}
Auth hint: {auth_hint or "none detected"}
Changed files (from git diff):
  {list}
</context>

<files_to_read>
- skills/bonsai-verify-ui/references/test-planner-agent.md  (agent protocol)
- {spec_path}                                                (intent)
- {plan_path}                                                (what was built)
- ./CLAUDE.md                                                (project conventions; skip if not present)
</files_to_read>
```

The subagent reads the files, explores the source tree for each file in the changed list to identify actual selectors and routes, derives scenarios, and returns YAML.

### Test planner agent protocol (`references/test-planner-agent.md`)

Adapted from `gsdn-verify-work/references/test-planner-agent.md`. Three substantive differences from the gsdn original:

1. **Input sources are spec + plan + source code**, not phase SUMMARY files + PLAN must_haves frontmatter. The planner derives scenarios from:
   - The spec's requirements / acceptance criteria section (whatever heading structure the spec happens to use — it reads the whole document)
   - The plan's task list — each task with a user-facing outcome becomes at least one test
   - The list of changed files — every file in the list must be covered by at least one test or marked `untestable` with a reason
2. **Coverage requirements are mandatory, not a budget.** The upstream gsdn agent uses a 5-15 test budget and prefers "meaningful" over "many shallow tests." We drop the cap entirely. The planner's responsibility is to cover every changed surface and every edge case it can observe. If the diff produced 15 changed files, the plan covers all 15 — it does not sample. Specific coverage requirements baked into the protocol:
   - **Happy path** for every user-facing change (every new/modified page, form, component, interactive element)
   - **Validation failures** for every form field that has visible constraints (required, type, min/max, regex). One test per constraint, not one test per form.
   - **Empty states** for every list, table, or collection that can legitimately be empty (zero results, no data, empty search)
   - **Auth boundaries** for every route that is protected — unauthenticated access must render the expected denial (redirect, 401 page, empty state). If no auth exists in the project, skip this bucket.
   - **Error states** for every observable failure mode (API 4xx/5xx, network failure, validation server error) where the UI is expected to render an error message
3. **Coverage audit step (new).** Before returning the YAML block, the planner walks each file in `<context>.changed_files` and checks it has at least one test that references it (URL points to the file's route, or a component selector derived from the file, or a form field whose source is in the file). Missing coverage has two resolutions:
   - Add a test. Preferred.
   - Mark the file `untestable` with an explicit reason in a separate `untestable_files:` section of the YAML output. Acceptable reasons: backend-only file, config/schema file with no UI surface, migration, build tooling, documentation. Un-acceptable reasons: "hard to test," "no selectors," "unsure." If the planner can't justify untestability, it has to add a test.

### Selector discovery

Same priority order as the gsdn upstream:

1. `data-testid="..."` — grep source for these first
2. `aria-label="..."` — second choice
3. `role="..." + name` — third
4. Semantic HTML — `button`, `input[type="email"]`, `h1`, `nav a`
5. CSS class — last resort, fragile

Never use: generated class names (CSS-module hashes, Tailwind utility selectors), positional selectors (`nth-child`, `first-of-type`), XPath.

The planner greps the actual source files in the changed list — it does not guess selectors.

### Auth detection

Same as gsdn:

1. Look for auth middleware, guards, session checks in the route/page source files
2. Check for login pages and auth flow components
3. Look for test credentials in `.env.test`, `.env.local`, `.env.development`, and `CLAUDE.md`
4. If credentials found, build an `auth` section in the YAML plan with login URL, credentials, selectors, and a success indicator selector
5. If no credentials found and auth exists, emit a warning in the YAML header comment — the execution phase will print this to the user and auth-required tests will be skipped with reason `"no test credentials available"`

### Output format

Each test is a dict with fields `id` (int), `name` (str), `url` (relative path), `requires_auth` (bool, defaults false, true if the URL is under an auth-protected route tree), `depends_on` (list of ids), `wait_for` (selector or null), `setup_actions` (list), `assertions` (list). The planner fills `requires_auth` based on its route-level auth analysis — this is what the executor reads in Phase 3 to decide whether to run the auth setup sequence before the test.

```yaml
<test_plan>
base_url: http://localhost:3000

auth:
  required: false
  # If required: true, include:
  # login_url: /login
  # credentials:
  #   email: test@example.com
  #   password: testpassword
  # email_selector: input[type="email"]
  # password_selector: input[type="password"]
  # submit_selector: button[type="submit"]
  # success_indicator: "[data-testid='dashboard']"

tests:
  - id: 1
    name: "Dashboard loads with project list"
    url: /dashboard
    requires_auth: true
    depends_on: []
    wait_for: "[data-testid='project-list']"
    setup_actions: []
    assertions:
      - type: element_exists
        selector: "[data-testid='project-list']"
        expected: "Project list container is present"
      - type: element_text
        selector: h1
        expected: "Dashboard"
      - type: no_console_errors
        expected: "No JavaScript errors in console"

  - id: 2
    name: "New project form — happy path"
    url: /projects/new
    requires_auth: true
    depends_on: [1]
    wait_for: "form"
    setup_actions:
      - tool: fill
        selector: "input[name='title']"
        value: "Test Project"
      - tool: fill
        selector: "textarea[name='description']"
        value: "Test description"
      - tool: click
        selector: "button[type='submit']"
    assertions:
      - type: navigation
        expected: "/projects/"
      - type: element_text
        selector: "[data-testid='success-message']"
        expected: "Project created"

  - id: 3
    name: "New project form — validation failure on empty title"
    url: /projects/new
    requires_auth: true
    depends_on: [1]
    wait_for: "form"
    setup_actions:
      - tool: click
        selector: "button[type='submit']"
    assertions:
      - type: element_exists
        selector: "[data-testid='error-title-required']"
        expected: "Validation error for missing title"

untestable_files:
  - path: prisma/migrations/20260415_add_project.sql
    reason: "Database migration, no UI surface"
</test_plan>
```

### Validation after subagent returns

The orchestrator parses the `<test_plan>` block and rejects it with a retry if:

- The YAML is invalid
- Any test is missing `id`, `name`, `url`, or `assertions`
- Any assertion is missing `type` or `expected`
- Any URL is absolute (contains `http://` or `https://`) instead of relative
- Any selector uses forbidden patterns (`nth-child`, XPath, CSS-module hash format)
- Any file in `<context>.changed_files` is absent from both `tests[].url`-referenced routes / selectors AND from `untestable_files`

On retry, the orchestrator re-dispatches with an appended note explaining what failed. After two retries it warns the user and offers: "proceed with the partial plan," "switch to interactive mode where you describe the tests," or "abort."

---

## Phase 3 — Test Execution

Main context runs the test plan via `mcp__chrome-devtools__*` tools. Deterministic loop, no subagents, no model calls inside this phase — it's a mechanical translation from YAML to tool calls.

The execution pattern is copied almost verbatim from `gsdn-verify-work/references/chrome-devtools-execution-patterns.md`. Stripping the gsdn-specific wording and keeping the rest unchanged. This is the one file where near-duplication with the personal gsdn skill is fine — it's a lookup table for the assertion-type → MCP-tool mapping, and there's no cleaner factoring that would prevent the duplication.

**Per-test loop:**

1. **Dependency skip.** If `depends_on` includes a test with status FAIL, mark current test SKIP with reason `"depends on test #{id} which failed"`. Only skip on FAIL, not on SKIP (avoid cascading skips from a single root failure).
2. **Auth check.** If the plan's `auth.required` is true and the auth setup sequence has not yet run this session, run it first:
   - `navigate_page(auth.login_url)`
   - `wait_for(auth.email_selector)`
   - `fill(auth.email_selector, auth.credentials.email)`
   - `fill(auth.password_selector, auth.credentials.password)`
   - `click(auth.submit_selector)`
   - `wait_for(auth.success_indicator)` with 5s timeout
   - If success indicator not found, mark auth as FAILED and skip every test in the plan whose URL requires auth (detected by the planner and encoded in a `requires_auth` field per test, defaulting to true for any test under the same URL tree as the auth-protected pages)
3. **Navigate.** `navigate_page(test.url)` where `test.url` is concatenated with `base_url`.
4. **Wait.** `wait_for(test.wait_for)` with 5s timeout, or 2s pause if `wait_for` is absent.
5. **Setup actions.** For each action in `setup_actions`:
   - `click` → `mcp__chrome-devtools__click(selector)`
   - `fill` → `mcp__chrome-devtools__fill(selector, value)`
   - `press_key` → `mcp__chrome-devtools__press_key(key)`
   - `hover` → `mcp__chrome-devtools__hover(selector)`
   - After each action, 500ms pause or a `wait_for` if the action implies a navigation
6. **Assertions.** For each assertion in `assertions`:

   | type | MCP tool | Check |
   |---|---|---|
   | `element_exists` | `take_snapshot` | selector present in DOM snapshot |
   | `element_text` | `evaluate_script` | `document.querySelector(sel)?.textContent?.trim()` matches/includes expected |
   | `element_value` | `evaluate_script` | `document.querySelector(sel)?.value` matches expected |
   | `element_count` | `evaluate_script` | `document.querySelectorAll(sel).length` matches expected |
   | `element_visible` | `evaluate_script` | `getComputedStyle(el).display !== 'none' && visibility !== 'hidden'` |
   | `navigation` | `evaluate_script` | `window.location.pathname` matches expected |
   | `url_contains` | `evaluate_script` | `window.location.href.includes(expected)` |
   | `network_call` | `list_network_requests` | at least one request matches URL pattern |
   | `no_console_errors` | `list_console_messages` | no error-level messages after filtering known noise |
   | `visual` | `take_screenshot` | always PASS, screenshot flagged for human review |

7. **Evidence.** After each test, `take_screenshot`. On FAIL, additionally grab `list_console_messages` and `list_network_requests` and attach to the test result.
8. **Record.** Append to the orchestrator's in-memory `TEST_RESULTS` array with `{id, name, url, status, assertions: [per-assertion pass/fail + details], evidence_path, console_errors?, failed_requests?}`.
9. **Progress.** Print one line: `Test {i}/{N}: {name} — {PASS|FAIL|SKIP}`. No other output during the loop.

**Console noise filter** (applied to `no_console_errors` and `console_errors` evidence collection):

Ignore:
- React development warnings (`Warning:`, `You are running React in development mode`)
- Hot module reload messages (`[HMR]`, `[Fast Refresh]`)
- Favicon 404 (`GET /favicon.ico 404`)
- Source map warnings (`DevTools failed to load source map`)

Never ignore:
- Next.js hydration mismatch warnings — these usually indicate real bugs
- Any `console.error(...)` call originating from app code
- Uncaught exceptions
- Failed `fetch`/XHR responses (4xx, 5xx, network errors)

**Error recovery:**

- **MCP tool failure** (transient error, timeout) → wait 2s, retry the exact same call once. Second failure → mark the assertion FAIL, continue to next assertion in the same test.
- **Three consecutive test FAIL results** → stop execution. Mark remaining tests SKIP with reason `"stopped after 3 consecutive failures"`. Proceed to Phase 4 with whatever results are in hand. This prevents a broken dev server from generating a 50-line red wall.
- **Navigation timeout** → mark current test FAIL, continue to next test.
- **Selector not found** → `take_snapshot` to capture current DOM state (as evidence), mark assertion FAIL with `"selector not found: {sel}"`, continue to next assertion.

---

## Phase 4 — Report & Failure Diagnosis

Write a markdown report, spawn diagnosis subagents on failures, commit, and present results.

### Report file

**Path:** `docs/superpowers/verify/YYYY-MM-DD-<topic>-verify.md` where `YYYY-MM-DD` is today's date and `<topic>` is derived from the plan filename by the following rules:

1. Take the plan's basename without `.md` extension (e.g. `docs/superpowers/plans/user-auth.md` → `user-auth`)
2. Strip any leading `YYYY-MM-DD-` date prefix if present (e.g. `2026-04-15-user-auth` → `user-auth`)
3. The remaining string is the topic

So `docs/superpowers/plans/2026-04-15-user-auth.md` produces `docs/superpowers/verify/2026-04-15-user-auth-verify.md`, and `docs/superpowers/plans/user-auth.md` run on the same day also produces `docs/superpowers/verify/2026-04-15-user-auth-verify.md`. Name collisions on a re-run the same day overwrite the previous report — this is intended behavior; the previous report is still in git history.

Create the `docs/superpowers/verify/` directory if it doesn't exist.

**Structure:**

```markdown
---
status: complete
branch: {branch}
spec: {spec_path}
plan: {plan_path}
started: {ISO timestamp, Phase 1 start}
updated: {ISO timestamp, Phase 4 commit}
---

## Summary

total: {N}
passed: {N}
failed: {N}
skipped: {N}

## Coverage

changed_files: {count from git diff}
covered_files: {count with at least one test referencing them}
untestable_files:
  - path: {path}
    reason: {reason from planner}

## Tests

### 1. {Test Name}

- **url:** {test url}
- **expected:** {description from test plan}
- **result:** pass
- **evidence:** Screenshot captured — referenced by resource ID `{uri returned by take_screenshot}`. Chrome DevTools MCP returns screenshots as resources, not file paths; the report records the resource URI so a future reader can re-fetch it via the MCP tool.

### 2. {Failing Test Name}

- **url:** {test url}
- **expected:** {description}
- **result:** fail
- **failed_assertions:**
  - type: element_text
    selector: "h1"
    expected: "Dashboard"
    actual: "Error"
- **console_errors:**
  - "Uncaught TypeError: Cannot read property 'name' of undefined at Dashboard.tsx:42"
- **failed_requests:**
  - GET /api/projects → 500 Internal Server Error
- **evidence:** Screenshot resource URI from `take_screenshot`
- **root_cause:** {from diagnosis subagent}
- **affected_files:**
  - src/pages/Dashboard.tsx:42
  - src/api/projects.ts:18
- **suggested_fix:** {one-line approach from diagnosis subagent, not implemented}

### 3. {Skipped Test Name}

- **url:** {test url}
- **expected:** {description}
- **result:** skipped
- **reason:** {why}
```

### Failure diagnosis

Only runs if at least one test has status FAIL. For each failing test, dispatch a sonnet subagent in parallel via a single message containing multiple `Task` tool calls. Parallel dispatch matters: N failing tests should not serialize into N sequential subagent invocations.

**Diagnosis subagent prompt:**

```
Diagnose the root cause of this test failure. You must NOT implement the fix —
only identify what's wrong and where. Return exactly these fields:

- root_cause: one concise sentence
- affected_files: list of file:line references to the specific code that
  caused the failure
- suggested_fix: one concise sentence describing the approach a human would
  take, not code

Test: {name}
URL: {url}
Expected: {expected}
Failed assertions: {detail}
Console errors: {list}
Failed network requests: {list}

Context:
- Spec: {spec_path}
- Plan: {plan_path}
- Changed files on this branch: {list}

Start by reading the spec and plan to understand intent, then read the changed
files referenced in the failure to identify the root cause.
```

The orchestrator merges each subagent's return values into the corresponding test entry in the report. If a diagnosis subagent fails to return structured output, mark `root_cause: "diagnosis failed, see raw output"` and include the raw response — do not block the report on a bad diagnosis.

### Commit

After the report file is written:

```bash
git add docs/superpowers/verify/{file}.md
git commit -m "verify: runtime UI verification for {topic}"
```

No hooks skipped, no amend, no force-push.

### User-facing output

Print a concise table to the terminal:

```
## Verification Complete — {topic}

Runtime tests: {passed}/{total} passed

| # | Test | Result | Details |
|---|------|--------|---------|
| 1 | Dashboard loads | PASS | — |
| 2 | New project happy path | FAIL | Missing project title validation |
| 3 | New project validation | SKIP | depends on #2 |

Report: docs/superpowers/verify/{file}.md
```

Then one of two next-step blocks:

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
- /clear + subagent-driven-development — hand the report to a fix pass
- Read the report and fix manually
```

No auto-advance, no proactive re-dispatch. The human picks the path.

---

## Tier 2 edit to `skills/subagent-driven-development/SKILL.md`

The full Tier 2 footprint for this feature.

### Change 1 — DOT flowchart node

Add an optional-style dashed edge and a new node between the final code reviewer and the finishing-a-development-branch handoff. Highlighted `lightyellow` to match the Bonsai convention for fork additions.

```dot
"Dispatch final code reviewer subagent for entire implementation" -> "Optional: /clear + invoke bonsai-verify-ui\n(runtime UI verification)" [style=dashed, color=gray50];
"Optional: /clear + invoke bonsai-verify-ui\n(runtime UI verification)" [shape=box style=filled fillcolor=lightyellow];
"Optional: /clear + invoke bonsai-verify-ui\n(runtime UI verification)" -> "Use superpowers:finishing-a-development-branch";
```

### Change 2 — new section "Optional Runtime Verification (Bonsai)"

Inserted between the Example Workflow section and the Advantages section of `skills/subagent-driven-development/SKILL.md`.

```markdown
## Optional Runtime Verification (Bonsai)

After the final code reviewer approves and before finishing the branch, you MAY
runtime-verify the UI in a real browser. This is skippable for non-UI work
(backend-only, config, docs), but strongly recommended for any task that
touches pages, components, forms, or user-facing flows.

**How:** `/clear` the current session (to drop all accumulated context), then in
the fresh session invoke the `bonsai-verify-ui` skill. It will read the spec,
plan, and branch git log, generate a test plan, execute it via Chrome DevTools
MCP, and write a report to `docs/superpowers/verify/`.

**Why /clear:** the verification runs in a fresh session with only disk state
as input. This avoids context pollution from the implementation flow and keeps
the verification independent of whatever the implementer believed they built.

**When to skip:** backend-only changes with no UI surface, pure refactors,
docs-only edits, config tweaks. Use your judgment — if a user could observe
the change in a browser, verify it.
```

### Change 3 — Integration section

Add to the existing "Integration" section at the bottom of `subagent-driven-development/SKILL.md` under a new "Optional downstream" sub-heading:

```markdown
**Optional downstream:**
- **bonsai-verify-ui** - Runtime UI verification in a fresh session after implementation completes. Invoke via /clear + skill trigger after the final code reviewer approves.
```

### Change 4 — marker comment

Single marker immediately above the new section, covering all three changes:

```html
<!-- BONSAI TIER-2 EDIT: "Optional Runtime Verification" section, corresponding DOT flowchart node (dashed edge + lightyellow fill), and Integration "Optional downstream" entry for bonsai-verify-ui. On upstream merge, ensure all three survive. -->
```

### Change 5 — manifest entry

Append to `docs/bonsai/tier-2-edits.md` following the existing template format. Dated `2026-04-15`. Includes:

- **File:** `skills/subagent-driven-development/SKILL.md`
- **Marker:** the exact marker text
- **Commit:** _pending_
- **What changed:** the three concrete additions described above
- **Why:** the team gap — static gates pass while the UI is broken, existing per-task and final reviewers can't catch that, fresh-session runtime verification closes the gap without bloating Tier 2
- **Verification:** after an upstream merge, open `skills/subagent-driven-development/SKILL.md` and confirm (a) the marker comment survives, (b) the "Optional Runtime Verification" section is still present between Example Workflow and Advantages, (c) the DOT flowchart has the dashed edge + lightyellow node, (d) the Integration section still has the "Optional downstream" entry. If any of those are missing, the merge clobbered intentional edits.

---

## File-change manifest

**New files:**

1. `skills/bonsai-verify-ui/SKILL.md` — orchestrator body with all four phases
2. `skills/bonsai-verify-ui/references/test-planner-agent.md` — sonnet subagent protocol with coverage requirements
3. `skills/bonsai-verify-ui/references/chrome-devtools-execution-patterns.md` — assertion type → MCP tool lookup table (near-verbatim from gsdn, stripped of gsd-specific wording)
4. `docs/superpowers/verify/` — directory, created by the skill on first run; no placeholder file committed

**Modified files:**

5. `skills/subagent-driven-development/SKILL.md` — DOT node + new section + Integration entry + marker comment
6. `docs/bonsai/tier-2-edits.md` — new manifest entry

**Explicitly NOT touched:**

- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/spec-reviewer-prompt.md`
- `skills/subagent-driven-development/code-quality-reviewer-prompt.md`
- `skills/writing-plans/SKILL.md`
- `skills/brainstorming/SKILL.md`
- Any Tier 1 skill (`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `receiving-code-review`, `requesting-code-review`, `using-git-worktrees`, `writing-skills`)
- `.mcp.json` or any MCP configuration — per the repo's "no MCP in plugin" rule, the skill assumes `mcp__chrome-devtools__*` tools are configured in the consuming project

---

## Open questions / risks

1. **Base URL detection edge cases.** Projects that run on `:3000` for one dev server and `:5173` for another (e.g., Next.js backend + Vite frontend) will have ambiguous detection. The one-line confirmation lets the user correct it, but projects with truly split frontends may need two verify passes. Documented but not solved.
2. **Auth credential source.** The planner looks for credentials in `.env.*` files, but teams that use Auth0 / Entra ID / Supabase / Clerk for dev auth won't have username+password anywhere on disk. The first `bonsai-*` skill iteration will work for the simple case (local auth with `.env.test` credentials); cloud-auth dev flows will get `auth: required: true` in the plan but `auth_hint: null` and the execution phase will skip auth-required tests with `"no test credentials available"`. Not a blocker — the tests for unauthenticated routes and error boundaries still run.
3. **Chrome DevTools MCP version drift.** The tool names we depend on (`mcp__chrome-devtools__navigate_page`, `click`, `fill`, `evaluate_script`, `take_snapshot`, etc.) are stable in the current MCP version, and the 2026 research surfaced `v0.19.0` with page routing that we're not yet using. Future MCP versions may rename or split these. The skill's executor phase has to track MCP version updates — but that's a ~10-line change in one reference file, isolated.
4. **Non-web projects.** The skill hard-assumes a web app with a Chrome-renderable UI. Mobile, CLI, and native desktop projects don't benefit. Out of scope — the "skippable for non-UI work" guidance in the Tier 2 breadcrumb covers this.
5. **Flaky tests.** If a real-world page has a 1%-flake rate, the 3-consecutive-failure stop rule could trigger on a genuinely-healthy deployment. The retry-once-on-tool-failure logic handles MCP-level flakes but not application-level flakes. Accepted risk for v1 — if it becomes a problem, add per-test retry-on-assertion-fail logic later.

## Out of scope for v1 (explicit)

- Parallel test execution (Chrome DevTools MCP v0.19.0 page routing — use it once the per-page contention stories stabilize)
- Mobile emulation (`mcp__chrome-devtools__emulate`) — the MCP tool is available but v1 only runs desktop-sized
- Lighthouse performance audits (`mcp__chrome-devtools__lighthouse_audit`) — different concern, separate skill later
- Network throttling / offline testing
- Visual regression (pixel-diff against a baseline) — screenshots are evidence, not baselines
- Cross-browser (Firefox, Safari, Edge)
- Integration with CI — the skill is interactive, runs locally, and assumes a dev server is already up
