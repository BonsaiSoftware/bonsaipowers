# Tier 2 Edits Manifest

Every intentional edit to a Tier 2 (orchestration) skill in this fork. Used as the authoritative reference during upstream merges — if a conflict hides or reverts an entry in this file, the resolution is wrong.

**What belongs here:** edits to files in `skills/brainstorming/`, `skills/writing-plans/`, `skills/executing-plans/`, `skills/subagent-driven-development/`, `skills/dispatching-parallel-agents/`, `skills/finishing-a-development-branch/`, `skills/using-superpowers/`.

**What does NOT belong here:** additive `bonsai-*` skills (Tier 3, track in git only), personal `~/.claude/` customizations, project-level `CLAUDE.md` overrides in consuming repos.

**On upstream merge:** read the index below first — do NOT read this whole file. For each file that had a merge conflict, jump to its index entries, open the full entry for each, find the marker comment (`<!-- BONSAI TIER-2 EDIT: ... -->`) in the edited file, and verify the described change is still present after the merge resolution. Files without conflicts only need a marker-presence check (`grep -rl "BONSAI TIER-2 EDIT" skills/`).

---

## Index

| Date | File(s) | Edit |
|---|---|---|
| 2026-04-10 | `skills/brainstorming/SKILL.md` | Upgrade step 1 (structured codebase recon) + insert step 4 (research unknowns) |
| 2026-04-12 | `skills/writing-plans/SKILL.md` | Insert Research section: context7, best-practices skills, owasp, pitfall scans |
| 2026-04-12 | `skills/executing-plans/SKILL.md` | Add skill loading + execution constraints (context7, OWASP, best-practices) |
| 2026-04-12 | `skills/subagent-driven-development/` (SKILL + prompts) | Add skill loading, execution constraints, OWASP verification to subagent prompts |
| 2026-04-12 | `skills/brainstorming/SKILL.md` | Harden research step (context7 HARD-GATE) + Azure-native preference in approaches |
| 2026-04-13 | `skills/brainstorming/SKILL.md` | Harden research step: WebSearch into HARD-GATE matching context7 |
| 2026-04-15 | `skills/subagent-driven-development/SKILL.md`, `skills/executing-plans/SKILL.md` | Demote using-git-worktrees from REQUIRED to OPTIONAL |
| 2026-04-15 | `skills/brainstorming/SKILL.md` | REMOVED the `test-random` smoke test step (and the `test-random` skill) |
| 2026-04-15 | `skills/subagent-driven-development/SKILL.md` | Add optional runtime UI verification breadcrumb |
| 2026-04-24 | `skills/writing-plans/SKILL.md` | Speed-mode plan format (Dependency Graph, Shared Infrastructure, Waves, Flow, 3-step tasks) |
| 2026-04-24 | `skills/subagent-driven-development/SKILL.md` | Wave-based controller loop with parallel dispatch + wave commit + bisect protocol |
| 2026-04-24 | `skills/subagent-driven-development/implementer-prompt.md` | Scope lockdown, shared-infra read-only, explicit staging, no-commit, staged-files reporting |
| 2026-04-24 | `skills/subagent-driven-development/spec-reviewer-prompt.md` | Scoped diff review limits reviewer to the task's declared files |
| 2026-06-12 | `skills/brainstorming/SKILL.md` | Dedupe checklist vs process sections + parallel research queries |

---

## Entry template

```markdown
### <YYYY-MM-DD> — <skill-name>: <one-line summary>

**File:** `skills/<skill>/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: <short description> -->`
**Commit:** `<sha>` (fill in after commit)

**What changed:** <concrete description of the diff>

**Why:** <the team need that drove the edit — what would have broken without it>

**Verification:** <how to confirm the edit is still working after an upstream merge>
```

---

## Entries

### 2026-04-10 — brainstorming: upgrade step 1 (structured codebase recon) + insert step 4 (research unknowns)

**File:** `skills/brainstorming/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: Step 1 (structured codebase recon additions), step 4 (research unknowns via context7 + WebSearch with HARD-GATE on BOTH tools), and step 5 (Azure-native preference in approach proposals) are team-specific additions not in upstream. On upstream merge, ensure these steps survive and the numbering stays consistent (upstream has no step 4; its steps 1-9 map to our 1-3, 5-10 with step 1 upgraded). The Research unknowns process section also has a HARD-GATE requiring at least one context7 query AND at least one WebSearch query — preserve both. -->`
**Commit:** _pending_

**Note on numbering:** the earlier shape of this edit was step 2 (recon) and step 5 (research) because a `test-random` smoke test occupied step 1. That smoke-test step was removed on 2026-04-15 — see the removal entry below. The recon step is now step 1 and the research step is now step 4.

**What changed:** Two related additions to the brainstorming checklist and its accompanying DOT flowchart and Process-section prose:

1. **Step 1 upgraded** from generic "Explore project context — check files, docs, recent commits" to "Structured codebase recon": check files/docs/commits PLUS grep the dependency manifest for existing libraries, scan the nearest `CLAUDE.md` for project conventions, find the most similar existing feature and read how it's structured. The rationale is baked into the step ("proposing Redux when the repo is Zustand wastes everyone's time"). DOT node recolored to `lightyellow` to mark the Bonsai edit.
2. **Step 4 inserted** between "Ask clarifying questions" (step 3) and "Propose 2-3 approaches" (was 4, now 5). The new step, "Research unknowns", is a conditional research gate that leans toward doing the research — it is skipped only for very small tweaks or obviously-familiar territory. It directs the agent to use two tools with specific granularity constraints:
   - **context7** for API/library feasibility spot-checks at yes/no granularity ("does NestJS support WebSocket + guards on the same decorator?"), one query per uncertain question. Implementation details are explicitly out of scope — those belong in writing-plans.
   - **WebSearch** for prior-art scans on problems with well-trodden solutions ("how do teams typically implement multi-tenant row-level security in Postgres 16?"), one well-framed query rather than several shotgun searches. Results feed the approach proposal directly.
   Downstream effects: step 5 ("Propose 2-3 approaches") now explicitly says approaches ruled out by the research step are off the table and approaches surfaced by it are on it. A new "Researching unknowns (before proposing approaches)" subsection was added to the Process body (right before "Exploring approaches") with the full guidance on when to use each tool and what NOT to research. The DOT flowchart gained a `Research unknowns\n(context7 + WebSearch)` node (lightyellow) between clarifying questions and approach proposal.

Steps 4-9 from upstream's version are renumbered to 5-10 in our checklist, and the final count is 10 checklist items.

**Why:** Two pain points the team has hit repeatedly. (1) Approach proposals that don't fit the repo: the agent proposes an approach using a library the project isn't using, or contradicting a convention written down in `CLAUDE.md` that the agent never read. The upgraded step 1 forces a targeted recon (dependency manifest + `CLAUDE.md` + similar feature) instead of a vague "check files, docs, recent commits" that the agent can rationalize skipping. (2) Approach proposals that ignore well-trodden solutions or include ones that aren't actually feasible in the chosen framework: either the agent didn't know about a standard pattern because its training data is stale, or it assumed a framework supports something it doesn't and proposed an approach that falls over during planning. The new step 4 gives the agent two targeted external tools with explicit granularity — yes/no feasibility questions for context7, prior-art scans for WebSearch — and tells it to lean toward using them. Skipping the step is permitted only for very small tweaks, to avoid adding ceremony to trivial brainstorms.

**Verification:** In a fresh Claude Code session, run a brainstorm for a non-trivial feature that touches an unfamiliar library or domain. The agent should: (a) in step 1, grep `package.json`/equivalent and read `CLAUDE.md` before asking clarifying questions, (b) after clarifying questions but before proposing approaches, do at least one `context7` query AND at least one `WebSearch` call (or explicitly state why it is skipping — which should only happen for very small tweaks), (c) reference what it learned from that research when presenting the 2-3 approaches. For a trivially small brainstorm (e.g., "add a new enum value"), the agent may skip step 4 entirely; confirm it at least considered the step rather than silently dropping it. If the agent skips the research step on a non-trivial brainstorm without justification, re-read `skills/brainstorming/SKILL.md` step 4 text and the "Researching unknowns" subsection in the Process body, and confirm both survived the most recent upstream merge.

---

### 2026-04-12 — writing-plans: insert Research section with context7, best-practices skills, owasp, pitfall scans

**File:** `skills/writing-plans/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: Research section (steps 1-6) and "How Research Flows Into the Plan" table are team-specific additions not in upstream. On upstream merge, ensure both sections survive between Scope Check and File Structure. The Plan Document Header template also has an added **Required Skills:** field — keep it. -->`
**Commit:** _pending_

**What changed:** Three additions to the writing-plans skill:

1. **New `## Research (before writing tasks)` section** inserted between Scope Check and File Structure. Contains six numbered research sub-steps that the planner must run before designing the file structure or writing tasks:
   - (1) Resolve current APIs via context7 — pin library versions, get actual method signatures instead of guessing from training data.
   - (2) Best-practices skill load — conditionally invoke `nestjs-best-practices`, `vercel-react-best-practices`, or other stack-specific skills based on what the spec references. List them in the plan header.
   - (3) Security constraints via `owasp-security` — invoke when any task touches auth, input, data storage, or external APIs. Embed OWASP patterns as hard requirements on task steps, not as footnotes.
   - (4) Don't-hand-roll check — for each "build X" task, query context7 for existing maintained libraries. If one exists, rewrite the task from "implement" to "install and configure."
   - (5) Pitfall scan — query context7/WebSearch for common mistakes and gotchas per library. Embed as warning constraints above the relevant task steps.
   - (6) microsoft-docs — conditional on Azure/Microsoft services. Pull official code samples via `microsoft_code_sample_search`.

2. **New `## How Research Flows Into the Plan` section** with a mapping table showing where each type of research finding goes (library version → Tech Stack header, OWASP constraint → task step, pitfall → warning line, etc.). This prevents research from ending up in a separate document that the implementer ignores.

3. **Updated Plan Document Header template** — added `**Required Skills:**` field after `**Tech Stack:**` so implementers know which best-practices and security skills to load before executing the plan. Updated `**Tech Stack:**` placeholder to say "with pinned versions from research."

**Why:** The brainstorming skill's research step (added 2026-04-10) surfaces broad feasibility and prior-art, but writing-plans was still generating code blocks with guessed API signatures, no security constraints, and no awareness of existing libraries. Specific pain points: (1) Plans used training-data method signatures that had changed in newer library versions — implementers hit runtime errors on step 3. (2) Plans hand-rolled functionality that well-maintained libraries already provide — wasted implementation time and introduced bugs the library had already solved. (3) Security requirements (OWASP patterns) were either absent or relegated to a "security considerations" footnote that implementers skipped — embedding them as task-step constraints makes them un-skippable. (4) Known library pitfalls (e.g., Passport not catching ExpiredTokenError) weren't surfaced until the implementer hit them — a 30-second context7 query during planning prevents a 30-minute debugging session during execution.

**Verification:** In a fresh Claude Code session, brainstorm a non-trivial feature that touches a framework and auth (e.g., "add JWT-based auth guards to NestJS WebSocket handlers"). When writing-plans runs, confirm:
- The plan header has **Tech Stack:** with pinned versions (not just "NestJS, Passport")
- The plan header has **Required Skills:** listing `nestjs-best-practices` and `owasp-security`
- Code blocks in task steps use method signatures from context7, not guessed ones
- At least one task that was originally "build X" got rewritten to "install and configure Y"
- At least one pitfall warning (`⚠`) appears above a relevant step
- Auth-related tasks have inline OWASP constraints (e.g., "MUST validate JWT expiry")
- No research findings are in a separate "research notes" section — they're all embedded in tasks
If any of these are missing, re-read the Research section and mapping table in `skills/writing-plans/SKILL.md` and confirm the `<!-- BONSAI TIER-2 EDIT -->` marker survived the most recent upstream merge.

---

### 2026-04-12 — executing-plans: add skill loading + execution constraints (context7, OWASP, best-practices)

**File:** `skills/executing-plans/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: Step 1 item 5 (required skill loading) and Step 2 execution constraints (JIT context7 verification, OWASP security gates, best-practices compliance) are team-specific additions not in upstream. On upstream merge, ensure Step 1 keeps the skill-loading item and Step 2 keeps all three constraint sub-sections before Step 3. -->`
**Commit:** _pending_

**What changed:** Two additions to the executing-plans skill that close the loop from writing-plans' new Research section:

1. **Step 1 item 5 (skill loading)** — after the plan is loaded and reviewed, the executor reads the `**Required Skills:**` field from the plan header and invokes each listed skill (e.g. `nestjs-best-practices`, `owasp-security`). These become active constraints for the entire execution. If a listed skill can't be found, the executor stops and tells the user rather than proceeding without constraints.

2. **Three execution constraint sub-sections in Step 2** (between the per-task list and Step 3):
   - **Just-in-time API verification** — when a task step references a library API the executor isn't 100% sure about, it does one context7 query to verify the signature before writing code. This is verification, not research — the plan already decided the approach and pinned the version. The executor confirms the signature is correct, then writes it. No alternatives exploration, no investigation.
   - **Security gates** — if a task step has OWASP constraints (⚠ markers or explicit "MUST" requirements from the plan), the executor implements them exactly as specified. If it can't satisfy a constraint, it stops and asks rather than skipping or weakening. The verification step must confirm the constraint is met.
   - **Best-practices compliance** — if a required skill is loaded, the executor follows its patterns when writing code. Plan takes precedence on conflicts (the planner already made the tradeoff). Where the plan is silent, the skill fills in. This is pattern compliance, not research — the executor doesn't read reference files speculatively.

**Why:** The writing-plans skill now produces plans with `**Required Skills:**`, pinned versions in `**Tech Stack:**`, OWASP constraints embedded in task steps, and pitfall warnings. But the executor had no mechanism to load those skills or respect those constraints — it just said "follow plan steps exactly," which covered the code but silently ignored the skills/security/best-practices apparatus. Specific gaps: (1) Plans listed required skills but the executor never loaded them, so best-practices were invisible during implementation. (2) Plans pinned library versions but the executor guessed at API signatures from training data instead of verifying — producing code that compiled against the wrong version. (3) OWASP constraints in task steps were treated as advisory rather than hard requirements — the executor could skip or weaken them without stopping. The executor is now disciplined, not curious: it loads what the plan says to load, verifies what it's about to type, and treats security constraints as non-negotiable.

**Verification:** In a fresh session, execute a plan that has `**Required Skills:** nestjs-best-practices, owasp-security` in its header:
1. Confirm the executor invokes both skills during Step 1 before creating the TodoWrite
2. On a task with a pinned library version: confirm the executor does a context7 lookup to verify the API signature before writing the code (not after, not "I'll check later")
3. On a task with an OWASP constraint (e.g., "MUST use parameterized queries"): confirm it's implemented exactly, and the verification step explicitly checks the constraint is met
4. On a task where the plan is silent but `nestjs-best-practices` covers the pattern: confirm the executor follows the skill's pattern
5. If a required skill is missing: confirm the executor stops and tells the user rather than proceeding
If the executor skips skill loading or ignores constraints, re-read `skills/executing-plans/SKILL.md` and confirm Step 1 item 5 and the three Step 2 sub-sections survived the most recent upstream merge.

---

### 2026-04-12 — subagent-driven-development: add skill loading, execution constraints, and OWASP verification to subagent prompts

**Files:**
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/spec-reviewer-prompt.md`

**Marker:** `<!-- BONSAI TIER-2 EDIT: Controller setup section (skill loading + prompt injection), implementer-prompt.md additions (Required Skills, JIT context7, security gates, best-practices compliance), and spec-reviewer-prompt.md addition (OWASP verification) are team-specific additions not in upstream. On upstream merge, ensure all three files keep these additions. -->`
**Commit:** _pending_

**What changed:** Same execution constraints as executing-plans, adapted for the subagent dispatch model across three files:

1. **SKILL.md — new `## Controller Setup` section** (inserted before Model Selection). The controller reads `**Required Skills:**` from the plan header and invokes each skill during initial setup. It then includes skill names in every implementer prompt and OWASP constraints in spec reviewer prompts. The DOT flowchart's initial setup node was updated to include "load Required Skills" and highlighted `lightyellow`.

2. **implementer-prompt.md — three template additions:**
   - **`## Required Skills` section** (before "Before You Begin") — placeholder for the controller to fill in from the plan header. The implementer loads each listed skill before writing code.
   - **`## Execution Constraints` section** (after "Your Job") with three sub-sections:
     - *Just-in-time API verification* — one context7 query to verify an API signature before writing it. Verification, not research.
     - *Security gates* — implement OWASP constraints exactly as specified. If can't satisfy, report BLOCKED instead of skipping.
     - *Best-practices compliance* — follow loaded skills. Plan wins on conflicts; skill fills gaps.

3. **spec-reviewer-prompt.md — `Security constraint verification` sub-section** (after "Misunderstandings", before final report). When a task has OWASP constraints, the spec reviewer verifies each one is actually implemented in the code — a missing or weakened security constraint is a spec failure, same as a missing feature. The controller includes this section only when the task has security constraints.

**Why:** Same gap as executing-plans — the writing-plans skill now produces plans with `**Required Skills:**` and OWASP constraints, but the subagent execution path had no mechanism to load those skills or enforce those constraints. The additional complexity here is that subagents are fresh agents with no inherited context. The controller must (a) load skills itself for coordination awareness, (b) inject skill names into implementer prompts so subagents load them too, and (c) inject OWASP constraints into spec reviewer prompts so security requirements get verified independently, not just by the implementer's self-review. Without the spec reviewer addition, an implementer could claim "MUST use parameterized queries" is satisfied while the actual code uses string concatenation — the reviewer now catches this.

**Verification:** In a fresh session, use subagent-driven-development to execute a plan with `**Required Skills:** nestjs-best-practices, owasp-security`:
1. Confirm the controller loads both skills during initial setup (before dispatching any subagent)
2. Confirm the implementer prompt includes a `## Required Skills` section listing the skills
3. Confirm the implementer prompt includes the `## Execution Constraints` section
4. On a task with a pinned library version: confirm the implementer does a context7 query before writing code
5. On a task with OWASP constraints: confirm the spec reviewer's prompt includes the security constraint verification section, and the reviewer independently verifies the constraints are met
6. If a required skill is missing: confirm the controller stops before dispatching any subagent
If any of these are missing, check all three files (`SKILL.md`, `implementer-prompt.md`, `spec-reviewer-prompt.md`) and confirm the Bonsai additions survived the most recent upstream merge.

---

### 2026-04-12 — brainstorming: harden research step (context7 HARD-GATE) + Azure-native preference in approaches step

**File:** `skills/brainstorming/SKILL.md`
**Marker:** Updated the existing `<!-- BONSAI TIER-2 EDIT -->` marker to cover these additions.
**Commit:** _pending_

**Note on numbering:** as of 2026-04-15, the research step is step 4 and the approaches step is step 5 (previously 5 and 6 respectively — the shift is because the `test-random` smoke test that used to be step 1 was removed). This entry is described in the current numbering.

**What changed:** Two additions to the brainstorming checklist and process body:

1. **Research step (step 4) hardened with HARD-GATE** — changed from "lean toward doing this" to mandatory. At least one context7 query is now required for any brainstorm involving external libraries, APIs, cloud services, or framework features. Skip is only permitted for pure internal refactors or config-only tweaks with zero external dependencies. Added explicit callout: "If you believe you can skip context7 entirely, you are almost certainly wrong — your training data is stale, verify anyway." The process body's "Researching unknowns" subsection now has a `<HARD-GATE>` block enforcing the same rule.

2. **Azure-native preference in approaches step (step 5) and "Exploring approaches"** — when a feature involves cloud infrastructure, storage, auth, messaging, or any service Azure provides natively, the agent must include the Azure-native option and recommend it by default. Non-Azure alternatives only recommended when there's a concrete technical reason (cost, feature gap, existing lock-in). Examples given: Azure Service Bus over self-hosted RabbitMQ, Azure Blob Storage over S3, Entra ID over custom auth, Azure Key Vault over manual secret management.

**Why:** (1) The research step's original "lean toward" language gave agents an escape hatch to rationalize skipping context7 ("I already know this API"). Observed in practice: agent skipped context7 entirely during a brainstorm involving the GitHub Contents API via Octokit, only acknowledging the skip when the user pointed it out. A HARD-GATE makes the requirement unambiguous. (2) The team builds on Azure — proposing AWS-native or self-hosted alternatives wastes brainstorming time and leads to approaches that don't fit the deployment target. Making Azure-native the default recommendation eliminates this friction.

**Verification:** In a fresh session, brainstorm a feature that involves an external library AND a cloud service (e.g., "add file upload to Azure Blob Storage with presigned URLs"):
1. Confirm the agent runs at least one context7 query during the research step (step 4) before proposing approaches
2. Confirm the agent does NOT skip the research step with a rationalization like "I already know how Blob Storage works"
3. Confirm the Azure-native option (Blob Storage + SAS tokens) is present in the 2-3 approaches and is the recommended one
4. If a non-Azure alternative is recommended, confirm there's a stated concrete technical reason
If the agent skips context7 or doesn't default to Azure-native, re-read the research step (HARD-GATE), the approaches step (Azure-native preference), and the "Researching unknowns" and "Exploring approaches" subsections.

---

### 2026-04-13 — brainstorming: harden research step WebSearch into HARD-GATE matching context7

**File:** `skills/brainstorming/SKILL.md`
**Marker:** Updated the existing `<!-- BONSAI TIER-2 EDIT -->` marker to cover this change.
**Commit:** _pending_

**Note on numbering:** as of 2026-04-15, the research step is step 4 (previously step 5 — the shift is because the `test-random` smoke test that used to be step 1 was removed). This entry is described in the current numbering.

**What changed:** The research step's WebSearch bullet promoted from "use sparingly" optional tool to mandatory, matching the context7 HARD-GATE. Three coordinated edits:

1. **Checklist research step WebSearch bullet** — changed from "when the problem has well-trodden solutions your training data may not reflect ... Use sparingly" to "at least one query required. Your training data is stale and frequently misses approaches teams have converged on since." Added the same "you are almost certainly wrong to skip" framing as context7. Preamble changed from "Two quick external checks, scaled to the task" to "Two external checks, both required."

2. **Process body `<HARD-GATE>` block** — updated to require BOTH a context7 query AND a WebSearch query before proposing approaches, with the same narrow escape hatch (zero external libs/APIs/cloud services). If either is skipped, the agent must state why in a single sentence.

3. **Process body WebSearch description** — reframed from "for prior-art scans when the problem has well-trodden solutions" to "at least one query required for prior-art scans" with the stale-training-data rationale promoted to the lead and the "you are almost certainly wrong to skip" line added.

**Why:** Despite the 2026-04-10 addition of WebSearch to the research step and the 2026-04-12 context7 hardening, observed behavior in practice is that the agent runs context7 (which has a HARD-GATE) and rationalizes skipping WebSearch ("one query already counts as research," "the problem is well understood enough," "I know the prior art"). The result: brainstorms reflect training-data knowledge of approaches circa 2024/early-2025 and miss patterns teams have converged on since. WebSearch and context7 serve different purposes — context7 answers "does this API exist" while WebSearch answers "what approaches are teams actually using" — so they are not substitutes. Making WebSearch mandatory with the same HARD-GATE treatment eliminates the rationalization path.

**Verification:** In a fresh session, brainstorm a feature that touches prior art (e.g., "add background job retries with exponential backoff in NestJS"). Confirm the agent:
1. Runs at least one `context7` query during the research step (step 4)
2. Runs at least one `WebSearch` query during the research step (not skipped, not deferred to writing-plans)
3. References at least one finding from WebSearch when proposing approaches (e.g., "BullMQ's built-in retry config" or "the `p-retry` library pattern")
4. If WebSearch is skipped, the agent states why in a single sentence and the justification matches the escape hatch (pure internal refactor, no external deps)
If the agent skips WebSearch without justification, re-read `skills/brainstorming/SKILL.md` research step (step 4), the `<HARD-GATE>` block in the "Researching unknowns" subsection, and the WebSearch description in that same subsection, and confirm all three enforce the mandatory-query rule after the most recent upstream merge.

---

### 2026-04-15 — subagent-driven-development + executing-plans: demote using-git-worktrees from REQUIRED to OPTIONAL

**Files:**
- `skills/subagent-driven-development/SKILL.md`
- `skills/executing-plans/SKILL.md`

**Marker:** Each file has a dedicated `<!-- BONSAI TIER-2 EDIT: using-git-worktrees is demoted from REQUIRED to OPTIONAL ... -->` marker placed directly below the new "Optional workflow skills" block inside the `## Integration` section. These are separate from the earlier tier-2 markers in the same files (subagent-driven-development has its controller-setup marker near line 97; executing-plans has its step-1/step-2 marker near line 54) — keep all of them on merge.

**What changed:** Moved `superpowers:using-git-worktrees` out of the "Required workflow skills" list in both files' `## Integration` sections into a new "Optional workflow skills" list, labeled `Optional: Set up isolated workspace when the task benefits from isolation`. No other text in the Integration section was changed; the remaining "Required workflow skills" bullets (writing-plans, requesting-code-review, finishing-a-development-branch) stay in place. The safety floor — "Never start implementation on main/master branch without explicit user consent" at `executing-plans/SKILL.md:87` — is unchanged. The Tier-1 file `skills/using-git-worktrees/SKILL.md` is intentionally NOT edited; its internal "Called by" section (which still reads "REQUIRED before executing any tasks") is descriptive metadata and leaving it alone is the right tradeoff vs. touching a Tier-1 file.

**Why:** In the canonical Bonsai workflow for this repo, team members spend long sessions on `bonsai-custom` (the fork-maintenance branch) with no concurrent work to isolate from. The REQUIRED framing created needless friction every time a plan was executed — the agent would present a worktree choice as a gate to resolve, even though staying on the current branch was the obviously-correct answer. The softened framing lets the agent use judgment: invoke worktrees when isolation matters, skip when it doesn't. Auto-invocation of `using-git-worktrees` via its description trigger still works; only the "must set up before starting" framing is removed.

**Verification:** In a fresh Claude Code session on `bonsai-custom` in the bonsaipowers repo, point Claude at any existing plan and ask it to execute using subagent-driven-development. Confirm:
1. The agent does NOT treat worktree setup as a mandatory pre-execution gate — it proceeds with execution on the current branch unless there's a concrete isolation need.
2. The "Never start implementation on main/master branch without explicit user consent" safety rule still fires if the user is on `main` or `master`.
3. In `skills/subagent-driven-development/SKILL.md` and `skills/executing-plans/SKILL.md`, the `## Integration` sections have `superpowers:using-git-worktrees` under an **Optional workflow skills** heading, NOT under **Required workflow skills**, with the "Optional: Set up isolated workspace when the task benefits from isolation" label.
4. Both files still have their respective `<!-- BONSAI TIER-2 EDIT: using-git-worktrees is demoted ... -->` marker directly below the new Optional block.
If any of these are missing, re-read the `## Integration` sections of both files and confirm the worktree-demotion markers survived the most recent upstream merge.

---

### 2026-04-15 — brainstorming: REMOVED the `test-random` smoke test step (and the `test-random` skill)

**File:** `skills/brainstorming/SKILL.md` (and deletion of `skills/test-random/`)
**Marker:** none — this is a REMOVAL of a prior Bonsai edit, not an addition. There is no marker to preserve on merge because our file now matches upstream in this area again.
**Commit:** _pending_

**What changed:** The `test-random` smoke test that used to be step 1 of the brainstorming checklist was removed, along with the `skills/test-random/` directory that it invoked. The DOT flowchart node for the smoke test was also removed. As a result, brainstorming checklist numbering shifted by -1: what was step 2 (structured codebase recon) is now step 1, step 5 (research unknowns) is now step 4, step 6 (propose approaches) is now step 5, etc. Final count is 10 checklist items (previously 11). The 2026-04-10 entry above has been rewritten to the new numbering; the 2026-04-12 and 2026-04-13 brainstorming entries carry an explicit note about the renumbering.

**Why:** The smoke test served two purposes when introduced: (1) plug-and-play install verification, and (2) a reference implementation of the Tier 2 edit pattern. Over time, (1) became unnecessary — install failures surface through other symptoms before a brainstorm runs, and the friction of invoking a no-op skill on every brainstorm outweighed the diagnostic value. Purpose (2) is now served by the much meatier brainstorming-research Tier 2 edits (the context7/WebSearch HARD-GATE and the Azure-native preference), which demonstrate the pattern in a load-bearing way. The `test-random` skill itself was the only thing the step invoked, so it was deleted along with the step.

**Upstream-merge implication:** upstream has no step 1 smoke test and no `test-random` skill, so removing them brings us closer to upstream in this area. Future upstream merges should NOT introduce either back — if a merge resurrects a smoke test step or the `test-random` directory, that's upstream-side new work (unlikely) and would need a fresh decision.

**Verification:** In a fresh Claude Code session, start a brainstorm. Confirm:
1. The agent does NOT invoke `test-random` or mention "smoke test" as step 1.
2. The first step is "Structured codebase recon" (numbered 1).
3. The research step is numbered 4 (not 5), and the approaches step is numbered 5 (not 6).
4. `skills/test-random/` does not exist on disk.
5. `docs/bonsai/customizing/customizations-made.md` and `docs/bonsai/customizing/README.md` no longer reference the smoke test or the `test-random` skill.
6. `README.md` and `CLAUDE.md` no longer reference `test-random` for install verification.
If any of these are still present after a merge, the removal was partially reverted and should be re-applied.

---

### 2026-04-15 — subagent-driven-development: add optional runtime UI verification breadcrumb

**File:** `skills/subagent-driven-development/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: "Optional Runtime Verification" section, corresponding DOT flowchart node (dashed edge + lightyellow fill), and Integration "Optional downstream" entry for bonsai-verify-ui. On upstream merge, ensure all three survive. -->`
**Commit:** `c2d9442`


**What changed:** Five coordinated additions to `skills/subagent-driven-development/SKILL.md`, covered by two marker comments (a section-level marker above the Optional Runtime Verification section, and an adjacent `// BONSAI TIER-2 EDIT` comment inside the DOT block for merge-conflict visibility):

1. **New `## Optional Runtime Verification (Bonsai)` section** inserted between `## Example Workflow` and `## Advantages`. Tells the implementer that after the final code reviewer approves, they MAY `/clear` the session and invoke the `bonsai-verify-ui` skill to runtime-verify the UI in Chrome via MCP. Explicit guidance on when to skip (backend-only, config, docs).

2. **DOT flowchart update** in the `digraph process` block: new dashed edge (`style=dashed, color=gray50`) from the final code reviewer node to a new `lightyellow`-filled `Optional: /clear + invoke bonsai-verify-ui` node, and a solid edge from that node to the existing `Use superpowers:finishing-a-development-branch` node. Dashed edge visually marks the optionality.

3. **New `**Optional downstream:**` sub-section** in the `## Integration` section at the bottom, listing `bonsai-verify-ui` as an optional downstream step.

4. **Marker comment** immediately above the new section, covering all three changes as a single Tier 2 edit unit.

5. **Adjacent DOT-block marker** inside the digraph process block, using DOT line-comment syntax (`// BONSAI TIER-2 EDIT: ...`), placed immediately above the new dashed edge. Ensures merge-conflict resolvers working in the flowchart region see a marker without scrolling to the section-level marker 130 lines below.

**Why:** Every quality gate in `subagent-driven-development`'s per-task and final review loops is static — tests, code review, spec compliance. For UI work, static gates are necessary but not sufficient: a reviewer can approve code that lints, typechecks, has passing unit tests, matches the spec, and still produces a broken experience in a real browser (missing wiring, unhandled loading states, CORS errors, misconfigured routes, silent API failures, hydration mismatches). The team has seen this pattern repeatedly — "all green locally, broken on first manual test."

The new `bonsai-verify-ui` skill (Tier 3, at `skills/bonsai-verify-ui/`) closes this gap by driving Chrome DevTools MCP from a fresh `/clear`ed session with only disk state as input. The Tier 2 edit to `subagent-driven-development` exists to make that skill *discoverable* from the implementation flow — without the breadcrumb, users would have to remember to invoke it, which defeats the whole point of having it in the workflow. The section explicitly says "optional" and lists when to skip, so non-UI work isn't penalized.

The merge-conflict cost is deliberately minimized: the entire footprint is one section + one flowchart node + one integration line. No changes to implementer-prompt.md, spec-reviewer-prompt.md, or code-quality-reviewer-prompt.md. No changes inside the per-task loop. No new Required Skills, no new execution constraints.

**Verification:** In a fresh Claude Code session on any branch where `bonsaipowers` is installed:

1. Open `skills/subagent-driven-development/SKILL.md` and confirm the marker comment is present, immediately above an `## Optional Runtime Verification (Bonsai)` section that sits between `## Example Workflow` and `## Advantages`.
2. Render the `digraph process` block mentally (or via `dot -Tpng`) and confirm there is a dashed edge from `Dispatch final code reviewer subagent for entire implementation` to a `lightyellow`-filled `Optional: /clear + invoke bonsai-verify-ui` node, and a solid edge from that node to `Use superpowers:finishing-a-development-branch`.
3. In the `## Integration` section, confirm there is an `**Optional downstream:**` sub-section with an entry for `bonsai-verify-ui`.
4. Run a real subagent-driven-development flow end-to-end on a small UI feature. After the final code reviewer reports ✅, confirm the agent mentions the optional runtime verification breadcrumb in its summary (i.e., actually tells the user they can `/clear` and invoke `bonsai-verify-ui`).

If the marker, section, flowchart node, or integration entry is missing after an upstream merge, the merge-conflict resolution clobbered intentional Bonsai additions. Re-read this manifest entry and restore all five changes.

---

### 2026-04-24 — writing-plans: add speed-mode plan format (Dependency Graph, Shared Infrastructure, Waves, Flow field, 3-step task template)

**File:** `skills/writing-plans/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — see docs/bonsai/tier-2-edits.md -->` (two occurrences — after Plan Document Header template, after the new Speed-Mode Plan Sections)
**Commit:** `b7b7ab7`

**What changed:** Five additions to the writing-plans skill that establish a new default plan format ("speed-mode"):

1. **New `**Flow:**` field** in the Plan Document Header template, values `speed-mode` (default) or `careful-mode` (legacy per-task serial flow).
2. **New `## Speed-Mode Plan Sections`** top-level section inserted between Plan Document Header and Task Structure, containing three subsections:
   - `## Dependency Graph` — flat `blockedBy` listing per task.
   - `## Shared Infrastructure` — files that force solo-wave execution (package.json, lockfiles, root configs, migration dirs, barrel exports, NestJS root composition, CI files).
   - `## Waves` — computed by planner from graph + shared-infra list; one subsection per wave.
3. **New `**Wave:** N` per-task field** in the Task Structure template.
4. **New `### Speed-Mode Task Template`** subsection inside Task Structure — collapses the 5-step TDD template (test/verify-fail/impl/verify-pass/commit) to 3 steps (test+impl together / verify pass / stage). Commit step is removed — the controller commits at wave boundary.
5. **Updated `## Bite-Sized Task Granularity`** to show both careful-mode and speed-mode step lists.

**Why:** Speed-mode is the new Bonsai default flow, aimed at 3-5× wall-clock reduction on feature implementations via parallel implementers, parallel spec reviewers, and commit-per-wave. The plan format needs explicit graph + wave + shared-infra data so the controller can parallelize safely without worktree isolation (hard user constraint). The 3-step task template removes the per-step commit overhead and the explicit red-green split — both retained as correctness anchors are the JIT context7 verification and the final test-run-before-commit gate. Careful-mode is kept as an escape hatch for production hotfixes and security-critical work.

**Verification:** In a fresh session, brainstorm a small feature and run writing-plans. Confirm the generated plan has:
1. `**Flow:** speed-mode` in the header.
2. `## Dependency Graph`, `## Shared Infrastructure`, and `## Waves` sections populated.
3. Per-task `**Wave:** N` field.
4. Task steps following the 3-step speed-mode template (test+impl / verify / stage), NOT the 5-step legacy template.
5. No per-task commit step in the task template (controller commits at wave boundary).
If any of these are missing, confirm `<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) -->` markers survived the most recent upstream merge and re-apply the section additions.

---

### 2026-04-24 — subagent-driven-development: wave-based controller loop with parallel dispatch + wave commit + bisect protocol

**File:** `skills/subagent-driven-development/SKILL.md`
**Markers (two):**
- HTML marker above the new Wave-Based Controller Loop section: `<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — new wave-based loop replaces the per-task serial loop. See docs/bonsai/tier-2-edits.md. -->`
- DOT-comment marker inside the rebuilt DOT flowchart (supersedes the prior `// BONSAI TIER-2 EDIT: optional bonsai-verify-ui breadcrumb` comment): `// BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — wave-based graph replaces per-task serial graph. See docs/bonsai/tier-2-edits.md.`

**Commit:** `8c6ea75`

**What changed:** Four coordinated changes to the subagent-driven-development skill:

1. **The DOT flowchart for `## The Process`** replaced with a wave-based version. Previous graph had a `cluster_per_task` subgraph showing implementer → spec review → code-quality review sequence per task. New graph has a `cluster_wave` subgraph showing pre-dispatch checks → parallel N-implementer dispatch → parallel N-spec-reviewer dispatch → wave-boundary commit, with waves running sequentially. A `// BONSAI TIER-2 EDIT: ...` DOT comment is placed inside the graph block for merge-conflict visibility. **Note on label text:** the "spec reviewer result" diamond node uses the label `"All spec reviewers OK?"` rather than the design-doc's `"All spec reviewers ✅?"`; this was a deliberate ASCII-robustness choice made at dispatch time, both labels are semantically equivalent, and the rest of the skill body still uses ✅/❌ in prose.
2. **New `## Wave-Based Controller Loop` section** inserted between `## Controller Setup` and `## Model Selection`. Contains:
   - Per-wave flow steps 1-7: extract wave, pre-dispatch checks (clean working tree, pairwise-disjoint Files, shared-infra assertion, branch safety), parallel implementer dispatch in one message, collect results with BLOCKED handling, parallel spec reviewer dispatch, wave-boundary commit protocol (reset → re-stage declared files → verify scope → run tests → bisect if failure → one commit), advance.
   - End-of-feature flow: one final code-quality reviewer over full branch diff → finishing-a-development-branch → optional bonsai-verify-ui.
   - Speed-mode vs careful-mode flow-selection note.
3. **`## Red Flags` `**Never:**` list updated:**
   - REMOVED: `Dispatch multiple implementation subagents in parallel (conflicts)` — inverted under speed-mode, protected by file-scope discipline instead of a blanket prohibition.
   - ADDED: `Create git worktrees without explicit user request`; `Switch branches without explicit user request`; `Use git add -A or git add . inside an implementer subagent`; `Let implementers commit`; `Dispatch implementers across waves concurrently`.
4. **`## Advantages` `**vs. Manual execution:**`** — replaced the bullet `Parallel-safe (subagents don't interfere)` with `Wave-based parallelism (file-disjoint tasks dispatch concurrently; wave boundaries enforce state consistency)`.

**Why:** Speed-mode converts the controller from a per-task serial orchestrator into a wave-based parallel orchestrator. The prior red flag against parallel dispatch was correct under the old model (no file-scope discipline, no wave boundaries) and is wrong under the new one — we now dispatch N implementers in a single message protected by pre-dispatch disjointness checks. The new red flags encode the user's hard constraints (no worktrees, no branch switches) and the new staging/commit discipline. Commit-per-wave collapses what used to be 3N commits per feature into W (wave count), typically ~2-5× reduction. Cross-task regressions are caught at the wave-boundary test gate rather than leaking into the next wave.

**Verification:** In a fresh session with a small multi-task plan:
1. Render the `## The Process` DOT graph (or read the block) and confirm `cluster_wave` subgraph with pre-dispatch checks and parallel dispatch nodes, NOT `cluster_per_task`.
2. Execute the plan and observe the controller message containing multiple parallel `Task`/`Agent` tool-use blocks within a single turn for each wave's implementers (and again for the spec reviewers).
3. `git log --oneline` shows one commit per wave, not one per task.
4. `git worktree list` shows no new worktrees.
5. No `git checkout -b`, `git switch -c`, `git checkout <branch>`, or `git switch <branch>` commands execute.
6. `## Red Flags` section contains all five new bullets and does NOT contain `Dispatch multiple implementation subagents in parallel (conflicts)`.
If any of these regress, confirm all BONSAI TIER-2 markers (both the DOT block marker and the Wave-Based Controller Loop marker, plus the preserved older markers for controller setup and bonsai-verify-ui) survived the most recent upstream merge.

---

### 2026-04-24 — implementer-prompt: scope lockdown, shared-infra read-only, explicit staging, no-commit, staged-files reporting

**File:** `skills/subagent-driven-development/implementer-prompt.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — scope lockdown, shared-infra read-only, explicit staging, no-commit. See docs/bonsai/tier-2-edits.md. -->`
**Commit:** `28b45d9` (typo fix `debd911`)

**What changed:** Five coordinated template additions/edits to the implementer subagent prompt:

1. **New `## Your File Scope` section** — controller fills in from plan task's `**Files:**` block; implementer forbidden from writing outside the list; `BLOCKED: scope-expansion` escalation path documented.
2. **New `## Shared Infrastructure (read-only for this task)` section** — controller fills in from plan's `## Shared Infrastructure`; implementer treats these files as read-only; `BLOCKED: shared-infra` escalation path documented.
3. **New `## Staging Rules` section** — requires explicit `git add <file1> <file2>`; forbids `git add -A` and `git add .`; forbids committing (controller commits at wave boundary); requires reporting the exact staged-file list.
4. **`## Your Job` list rewritten** — removed step "4. Commit your work"; replaced with "4. Stage your work with explicit filenames"; added a trailing "Do NOT commit. The controller commits at wave boundary." note.
5. **`## Report Format` expanded** — added `**Staged files:**` field requiring the exact list of files passed to `git add`; documented the two new BLOCKED reason codes (`scope-expansion`, `shared-infra`) alongside existing `other`.

**Note on fence nesting:** the inner `git add` example in `## Staging Rules` uses an 8-space-indented code block (4 for outer template indent + 4 for code) rather than a triple-backtick fence, to avoid prematurely closing the outer prompt-template fence. Same convention applied in `spec-reviewer-prompt.md` (Task 4 below). Follow-up fixup commit `debd911` corrected a "your Your File Scope list" typo in the Staging Rules bullet to "listed in your `## Your File Scope` section".

**Why:** Speed-mode dispatches N implementers concurrently into the same checkout. Without file-scope discipline, two parallel implementers can silently corrupt each other's work via stray writes outside declared scope or via `git add -A`-style broad staging. This prompt encodes the discipline at the implementer level. The controller also enforces scope via re-staging from declared filenames at wave-boundary commit (belt-and-braces), but the implementer-side constraints surface violations earlier (as `BLOCKED: scope-expansion` reports) rather than being caught by the controller's diff inspection later.

**Verification:** In a fresh session, execute a small speed-mode plan. For a typical task:
1. The implementer prompt has `## Your File Scope`, `## Shared Infrastructure (read-only for this task)`, and `## Staging Rules` sections populated from the plan.
2. The implementer reports `**Staged files:** <list>` in its DONE report.
3. The implementer never runs `git add -A` or `git add .` (grep the transcript; should find zero occurrences from the implementer).
4. The implementer never runs `git commit` (same check).
5. If a task is authored to deliberately require touching an out-of-scope file, the implementer reports `BLOCKED: scope-expansion` rather than silently expanding.
If any of these regress, confirm the marker survived the most recent upstream merge.

---

### 2026-04-24 — spec-reviewer-prompt: scoped diff review limits reviewer to the task's declared files

**File:** `skills/subagent-driven-development/spec-reviewer-prompt.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — scoped diff review. See docs/bonsai/tier-2-edits.md. -->`
**Commit:** `3fb703e`

**What changed:** One template addition: a new `## Review Scope` section inserted between `## What Implementer Claims They Built` and `## CRITICAL: Do Not Trust the Report`. The section provides a `git diff --staged -- <file1> <file2> ...` command template (filled in by controller from the plan's Files block) and instructs the reviewer to review only that scope. Changes outside the declared scope are flagged as a scope violation (❌). The inner `git diff` block uses 8-space indentation to avoid nesting triple-backticks inside the outer prompt-template fence (same convention as Task 3).

**Why:** Speed-mode runs spec reviewers in parallel per wave. A reviewer that reads outside its scope will: (a) review files that other reviewers are already covering (wasted work, conflicting reports), and (b) potentially block the wave commit on issues that other tasks are responsible for. Scoping the diff keeps parallel reviewers independent. The scope-violation flag doubles as a second line of defense — if an implementer silently expanded scope past the controller's detection (unlikely but possible), the spec reviewer catches it via the diff inspection.

**Verification:** In a fresh session, execute a small speed-mode plan with 2 parallel tasks per wave:
1. Each spec reviewer's prompt has a `## Review Scope` section with a specific `git diff --staged -- <files>` command.
2. Each reviewer reports only on its task's files — no cross-task comments.
3. If an implementer silently writes to a file outside its scope, the spec reviewer flags the scope violation.

---

### 2026-06-12 — brainstorming: dedupe checklist vs process sections + parallel research queries

**File:** `skills/brainstorming/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: ... checklist steps 4-5 are deliberately one-line pointers to those sections, do not re-expand them. ... -->` (updated existing marker)
**Commit:** `03f60aa`

**What changed:** Checklist steps 4 and 5 no longer duplicate the full rule text — they are one-line pointers to the canonical "Researching unknowns" and "Exploring approaches" process sections, where each rule is now stated exactly once. Added a parallel-execution instruction (in checklist step 4 and as a bolded line before "Two tools, two purposes") telling the agent to issue all context7 and WebSearch queries in a single message instead of sequentially. No rule was weakened: the HARD-GATE, the skip conditions, the "training data is stale" framing, and the Azure-native preference are all unchanged in the process sections.

**Why:** The duplicated text cost ~800 tokens on every brainstorm for every team member and created drift risk (two copies of the same rule eventually disagree). Serialized research queries added 15-30s of avoidable latency per brainstorm; the queries are independent so there is no reason to run them one at a time.

**Verification:** In a fresh session, brainstorm a feature with an external dependency:
1. Step 4 still runs at least one context7 query AND at least one WebSearch query before approaches are proposed, issued together in one parallel message.
2. Step 5 still includes and recommends the Azure-native option for cloud-touching features.
3. The agent does not skip the research because the checklist line is now short — the HARD-GATE in the process section must still bind.

---
