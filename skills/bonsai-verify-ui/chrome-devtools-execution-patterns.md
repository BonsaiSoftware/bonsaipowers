# Chrome DevTools Execution Patterns

Protocol and mechanical reference for the Phase 3 test executor subagent of `bonsai-verify-ui`.
A Sonnet subagent reads this file at dispatch time and uses it as the authoritative source for
the per-test execution loop, Chrome DevTools MCP tool selection, assertion evaluation, evidence
collection, and error-recovery behavior. Follow it exactly.

---

## Per-Test Execution Loop

For each test in the plan, in order, run these steps. No parallelization — the browser is
single-threaded.

1. **Dependency skip.** If any id in `test.depends_on` has status FAIL in the running
   `TEST_RESULTS` array, mark this test SKIP with `skip_reason: "Depends on test #{id} which
   failed"` and continue to the next test.
2. **Auth setup if needed.** If `test.requires_auth: true` AND auth has not yet been set up
   AND `auth.required: true` in the plan, run the auth setup sequence (see § Auth Setup). If
   auth setup fails, record `auth_setup_status: FAIL`, mark this test and every subsequent
   `requires_auth: true` test SKIP with `skip_reason: "auth setup failed"`, and continue.
3. **Navigate.** `mcp__chrome-devtools__navigate_page(base_url + test.url)`.
4. **Wait.** `mcp__chrome-devtools__wait_for(test.wait_for)` with a 5s timeout. If
   `test.wait_for` is null, pause 2 seconds instead.
5. **Setup actions.** For each action in `test.setup_actions`, call the matching tool from the
   § Setup Action Mapping table. Pause 500ms after each action (or call `wait_for` on the next
   expected selector if more deterministic).
6. **Assertions.** For each assertion, use § Assertion Type Mapping to select the right tool
   and evaluate the result. Record `status: PASS | FAIL`, `actual` value, and keep the
   `selector`/`expected`/`type` fields from the plan.
7. **Evidence.** Call `mcp__chrome-devtools__take_screenshot` after the last assertion. Store
   the returned resource URI in `evidence_uri`. On any FAIL assertion, additionally call
   `mcp__chrome-devtools__list_console_messages` and `mcp__chrome-devtools__list_network_requests`
   (see § Evidence Collection).
8. **Record.** Append `{id, name, url, status, skip_reason?, assertions, evidence_uri,
   console_errors?, failed_requests?}` to `TEST_RESULTS`. Test `status` is PASS only when every
   assertion is PASS; otherwise FAIL (or SKIP per step 1/2).
9. **Progress.** Print one stdout line: `Test {i}/{N}: {name} — {PASS|FAIL|SKIP}`.

After the loop ends, return the full `<test_results>` YAML block per the dispatch prompt's
`<output_format>`.

---

## Connection Check

The main orchestrator has already confirmed Chrome is reachable in Phase 1. At the start of
Phase 3, the subagent re-selects the page to guarantee it's operating on the right target:

1. Call `mcp__chrome-devtools__select_page` with the `connected_page_id` passed in the
   dispatch `<context>` block.
2. If `select_page` fails (page closed, invalid id), fall back to
   `mcp__chrome-devtools__new_page(url=base_url)`.
3. If both calls fail, return the `<test_results>` YAML with every test marked SKIP
   (`skip_reason: "chrome disconnected"`), `auth_setup_status: N/A`, `stopped_early: true`,
   and `stopped_reason: "chrome disconnected before execution"`. Do not attempt further tool
   calls.

---

## Auth Setup

If the test plan has `auth.required: true`, run this sequence once before the first
auth-required test (not per-test):

1. `mcp__chrome-devtools__navigate_page` to `auth.login_url`
2. `mcp__chrome-devtools__wait_for` the `auth.email_selector` (5s timeout)
3. `mcp__chrome-devtools__fill` email selector with `auth.credentials.email`
4. `mcp__chrome-devtools__fill` password selector with `auth.credentials.password`
5. `mcp__chrome-devtools__click` submit selector
6. `mcp__chrome-devtools__wait_for` the `auth.success_indicator` (5s timeout)
7. If success indicator not found after 5s: mark auth as FAILED. Every test with
   `requires_auth: true` is SKIPPED with reason `"auth setup failed"`. Tests with
   `requires_auth: false` still run.

Auth state persists across tests (same browser session).

---

## Assertion Type Mapping

| Assertion type | Chrome DevTools MCP tool | How to check |
|---|---|---|
| `element_exists` | `take_snapshot` | Search DOM snapshot for selector. PASS if found. |
| `element_text` | `evaluate_script` | `document.querySelector('{selector}')?.textContent?.trim()` — check includes or matches expected |
| `element_value` | `evaluate_script` | `document.querySelector('{selector}')?.value` — check matches expected |
| `element_count` | `evaluate_script` | `document.querySelectorAll('{selector}').length` — check matches expected count |
| `element_visible` | `evaluate_script` | `getComputedStyle(el).display !== 'none' && getComputedStyle(el).visibility !== 'hidden'` |
| `navigation` | `evaluate_script` | `window.location.pathname` — check matches expected path |
| `url_contains` | `evaluate_script` | `window.location.href.includes('{expected}')` |
| `network_call` | `list_network_requests` | Filter requests by URL pattern. PASS if at least one match. |
| `no_console_errors` | `list_console_messages` | Filter for error-level messages, apply noise filter, PASS if none remain |
| `visual` | `take_screenshot` | No automated check. Capture screenshot, always PASS, flag for human review |

### evaluate_script patterns

**Text content check:**
```javascript
(() => {
  const el = document.querySelector('{selector}');
  return el ? el.textContent.trim() : null;
})()
```

**Navigation check:**
```javascript
window.location.pathname
```

**Element count:**
```javascript
document.querySelectorAll('{selector}').length
```

**Visibility check:**
```javascript
(() => {
  const el = document.querySelector('{selector}');
  if (!el) return false;
  const style = getComputedStyle(el);
  return style.display !== 'none' && style.visibility !== 'hidden';
})()
```

---

## Setup Action Mapping

| Plan action | Chrome DevTools MCP tool | Parameters |
|---|---|---|
| `click` | `mcp__chrome-devtools__click` | `selector` |
| `fill` | `mcp__chrome-devtools__fill` | `selector`, `value` |
| `press_key` | `mcp__chrome-devtools__press_key` | `key` |
| `hover` | `mcp__chrome-devtools__hover` | `selector` |

After each setup action, pause 500ms or call `wait_for` the next expected selector.

---

## Evidence Collection

**Every test:** `mcp__chrome-devtools__take_screenshot` after the last assertion completes
(pass or fail). Store the returned resource URI in the test result.

**On FAIL additionally collect:**
- `mcp__chrome-devtools__list_console_messages` — filter to recent messages since test started
- `mcp__chrome-devtools__list_network_requests` — filter to recent requests, keep 4xx/5xx

Store these in the test result for the report and for the diagnosis subagent's input.

---

## Error Recovery

**MCP tool failure (transient error, timeout):**
1. Wait 2 seconds
2. Retry the exact same tool call once
3. If retry also fails: mark current assertion FAIL with error details, continue to next
   assertion in the same test

**Three consecutive test FAIL results:**
1. Stop executing further tests
2. Mark remaining tests SKIP with reason `"stopped after 3 consecutive failures"`
3. Proceed to Phase 4 with whatever results are in hand

**Navigation failure (page doesn't load, timeout):**
1. Verify Chrome is still connected: `mcp__chrome-devtools__list_pages`
2. If no pages: stop execution, ask user to restart dev server
3. If pages exist but URL failed: mark test FAIL with error, continue to next test

**Selector not found:**
1. Take a `mcp__chrome-devtools__take_snapshot` to capture current DOM state as evidence
2. Mark assertion FAIL with `"selector not found: {selector}"`
3. Continue to next assertion in the same test

---

## Dependency Skip Logic

Before each test, check `depends_on`:

```
for dep_id in test.depends_on:
  if TEST_RESULTS[dep_id].status == "FAIL":
    mark test as SKIP with reason: "Depends on test #{dep_id} which failed"
    break
```

Only skip for FAIL, not for SKIP. This prevents cascading skips from a single root failure.

---

## Console Message Filtering

When checking `no_console_errors`, ignore:

- React development warnings (`Warning:`, `You are running React in development mode`)
- Hot module reload messages (`[HMR]`, `[Fast Refresh]`)
- Favicon 404 (`GET /favicon.ico 404`)
- Source map warnings (`DevTools failed to load source map`)

**Never ignore:**

- Next.js hydration mismatch warnings — these usually indicate real bugs
- Any `console.error(...)` call originating from app code
- Uncaught exceptions
- Failed `fetch`/XHR responses (4xx, 5xx, network errors)
