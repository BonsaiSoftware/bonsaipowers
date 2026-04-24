# Speed-Over-Commits Parallel Flow (Design)

**Date:** 2026-04-24
**Status:** Proposed — awaiting user approval before implementation plan
**Scope:** Tier 2 edits to `writing-plans`, `subagent-driven-development` (SKILL + prompts), and Tier 2 manifest
**Goal:** Make parallel-by-default, coarser-commits the baseline Bonsai flow for feature implementation while preserving JIT correctness gates (context7, spec review, final code-quality review).

---

## Goal

Cut feature-implementation wall-clock time by 3-5× by:
1. Dispatching **file-disjoint implementer subagents in parallel** within each "wave" of a plan's dependency graph.
2. Running **spec reviewers in parallel** per wave instead of sequentially.
3. Collapsing **per-TDD-step commits into one commit per wave**.
4. Dropping **per-task code-quality review** in favor of a single end-of-feature code-quality pass.

Retained as correctness anchors: JIT context7 API verification per task, per-task spec review (still required, just parallelized), TDD at task granularity (write tests + implementation together, not per-step red-green), final end-of-feature code-quality review, `owasp-security` gates, `**Required Skills:**` loading.

**Hard constraints from the user:**
- **Never create git worktrees without explicit user request.** Parallel work happens in the current checkout on the current branch.
- **Never switch branches without explicit user request.** The existing `finishing-a-development-branch` safety floor ("never start on main/master without explicit consent") stays; nothing in this design adds a branch switch.

This design is a **Tier 2 default change**, not a new Tier 3 skill. The speed-mode behavior is the baseline for `writing-plans` and `subagent-driven-development` across the team after these edits land.

---

## Architecture

Two Tier 2 orchestration skills are rewritten; their prompt companions are updated in lockstep:

```
writing-plans/SKILL.md
  └─ emits plans with Dependency Graph + Shared Infrastructure + Waves

subagent-driven-development/SKILL.md
  └─ controller: extract waves → disjointness check → parallel dispatch
                 → parallel spec review → wave commit → next wave
  ├─ implementer-prompt.md  → scope-locked, explicit-stage, no-commit
  ├─ spec-reviewer-prompt.md → scope-limited diff review
  └─ code-quality-reviewer-prompt.md → unchanged (still end-only)
```

No new files. No new skills. No worktree logic anywhere. No branch manipulation anywhere.

---

## Components

### 1. `writing-plans` — plan format additions

**New sections in the plan header block** (between `**Required Skills:**` and the task list):

1. **`## Dependency Graph`** — flat list, one line per task, using task IDs. Example:
   ```
   - Task 1: (none)
   - Task 2: blockedBy [Task 1]
   - Task 3: blockedBy [Task 1]
   - Task 4: blockedBy [Task 2, Task 3]
   ```

2. **`## Shared Infrastructure`** — files and directories that force solo-wave execution when a task touches them. Planner-authored, per feature. Default inclusions:
   - `package.json`, `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`
   - Root config: `tsconfig.json`, `.eslintrc*`, `prettier.config.*`, `vite.config.*`, `nest-cli.json`
   - Migration directories: `prisma/migrations/`, `src/**/migrations/`
   - Barrel exports the planner identifies (e.g. `src/index.ts`, `src/lib/index.ts`)
   - Global NestJS composition: root `app.module.ts`
   - CI files: `.github/workflows/*.yml`
   - Anything the planner judges "if two tasks edit this concurrently, state corrupts"

3. **`## Waves`** — computed by the planner from the graph + shared-infra list. One section per wave. Each wave lists the tasks that can run in parallel within it. A task that touches any shared-infra file gets a solo wave. Example:
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

**Per-task header additions:**
- Existing `Files:` block is now load-bearing: the controller asserts pairwise-disjoint `Files:` within a wave. Planner MUST list every file the task writes. Tasks that might touch shared-infra files must declare them — if they do, the task goes in a solo wave.
- New `**Wave:** N` line in each task header so the executor can cross-reference.

**Per-TDD-step change:**
- The existing 5-step task template (Write failing test / Verify fail / Write impl / Verify pass / Commit) collapses to a 3-step template for speed-mode plans:
  1. **Write test + implementation together** (with both code blocks shown).
  2. **Run test suite, verify pass** (exact command + expected).
  3. **Stage declared files** (explicit `git add <file1> <file2>` — NO `git add -A` or `git add .`).

  The commit step is **removed from the task template**. Committing is the controller's job at wave boundary (see component 2).

**Plan header additions:** a new `**Flow:** speed-mode (parallel waves, commit per wave)` line so the executor knows which discipline to apply. A future "careful-mode" value is the escape hatch for critical/production work, but the default is speed-mode.

### 2. `subagent-driven-development` — controller loop rewrite

The controller's main loop changes from "per task: dispatch implementer → spec review → quality review → next task" to "per wave: dispatch all implementers in parallel → dispatch all spec reviewers in parallel → wave commit → next wave."

Controller flow per wave:

1. **Extract wave tasks** from the plan's `## Waves` section.
2. **Pre-dispatch checks:**
   - `git status --porcelain` — working tree MUST be clean (no stray changes from a bailed-out previous wave).
   - Pairwise-disjoint assertion on each task's declared `Files:`. If overlap exists, split the wave and report the split — do NOT dispatch.
   - Shared-infrastructure assertion: no task in a multi-task wave declares a file in the plan's `## Shared Infrastructure` list. If any does, split.
3. **Dispatch implementers in parallel** — one single message containing N `Agent` tool calls (or `Task`, depending on SDK version), one per task. Each prompt includes the full task text, the task's declared `Files:`, the `## Shared Infrastructure` list, and the scope lockdown rules.
4. **Collect implementer results.** All must be `DONE` or `DONE_WITH_CONCERNS` before proceeding. Any `BLOCKED: scope-expansion` → split the offending task into a follow-up solo wave; the rest of the current wave's work stays staged. Any `BLOCKED: other` → escalate per existing rules.
5. **Dispatch spec reviewers in parallel** — one per task, each with its own scoped diff (`git diff --staged -- <task's declared files>`). Review loops per task are still possible — if a reviewer returns ❌, re-dispatch that task's implementer to fix, then re-review just that task. Other tasks' reviewers run to completion in parallel.
6. **Wave-boundary commit:**
   - Confirm all spec reviewers ✅.
   - `git reset` (unstage everything). Re-stage each task's declared files explicitly: `git add <file1> <file2> …` per task. This is belt-and-braces protection against an implementer that wrote outside scope.
   - `git diff --cached --name-only` — verify the staged file set matches the union of declared files. Any extra or missing file is a failure condition; escalate.
   - Run the full test suite (default: the project's test command from `CLAUDE.md` or `package.json`). If it fails at the wave boundary with all individual task tests passing, bisect by unstaging one task at a time to identify the offender. Dispatch a fix subagent, re-run.
   - Create **one commit** per wave with message: `feat(wave-N): <comma-separated task titles>` (or `feat(solo): <task title>` for solo waves). Controller does the commit — the implementer never commits.
7. **Advance to next wave.**

**End-of-feature** (no change from existing behavior, just stated for completeness):
- One final code-quality reviewer over the full branch diff.
- Hand off to `finishing-a-development-branch`.
- Optional `bonsai-verify-ui` breadcrumb still applies for UI work.

**Model selection** (unchanged): cheap model for mechanical implementers, standard for integration tasks, most capable for reviewers. Parallel dispatch does not change model selection per task.

### 3. `implementer-prompt.md` — scope lockdown

Three additions to the template:

1. **`## Your File Scope`** section — controller fills in the task's declared `Files:` list verbatim. The prompt text: "You MAY read any file in the repo. You MUST NOT write, create, or delete files outside this list. If you discover you need to touch a file not on this list, STOP and report `BLOCKED: scope-expansion` with the filename and the reason. Do NOT silently expand scope."

2. **`## Staging Rules`** section — the prompt text: "After implementing and running tests, stage your work with explicit filenames: `git add <file1> <file2>`. You MUST NOT use `git add -A`, `git add .`, or any glob form. You MUST NOT commit — the controller commits at wave boundary. When you report DONE, include the exact list of files you staged."

3. **`## Shared Infrastructure (read-only for this task)`** — controller fills in the plan's `## Shared Infrastructure` list. Prompt text: "These files are shared with other tasks or other waves. You MUST treat them as read-only for this task. If a shared-infra file needs to change, report `BLOCKED: shared-infra` with the file and a reason; the controller will schedule a solo wave."

The existing sections (`## Required Skills`, `## Execution Constraints` with JIT context7 + security gates + best-practices compliance) stay unchanged.

### 4. `spec-reviewer-prompt.md` — scoped diff

One addition: the controller provides a scoped diff command (`git diff --staged -- <declared files>`) in the prompt body and instructs the reviewer to review ONLY that scope. The existing OWASP verification sub-section stays.

### 5. `code-quality-reviewer-prompt.md` — unchanged

The end-of-feature reviewer already runs over the full branch diff. No change to this prompt. The only indirect change is that it now runs once per feature instead of once per task plus once at end, which it already handled anyway.

### 6. `docs/bonsai/tier-2-edits.md` — manifest entries

Three new entries, all dated 2026-04-24, referencing the implementation commit SHAs once those land. Each entry follows the existing template (what changed, why, verification steps). The verification steps for the main entry run an end-to-end speed-mode execution against a small plan with 2 waves and confirm: parallel dispatch happens, commits land one-per-wave, no worktrees are created, no branches are switched, scope lockdown fires on a deliberately-misbehaving implementer.

### 7. Marker comments at edit sites

Each edit site in a Tier 2 file gets a `<!-- BONSAI TIER-2 EDIT: speed-mode parallel flow (2026-04-24) — see docs/bonsai/tier-2-edits.md -->` comment. Per the existing convention, merge-conflict resolution uses these to identify intentional Bonsai changes vs. upstream edits.

---

## Data Flow

**Per feature:**
```
User-approved spec
  → brainstorming (writes spec)
  → writing-plans (reads spec, emits plan with graph+waves+scoped tasks)
  → subagent-driven-development (reads plan, executes wave-by-wave)
     ├─ wave 1: [impl, impl, impl] → [spec-review, spec-review, spec-review] → commit
     ├─ wave 2: [impl] (solo) → [spec-review] → commit
     ├─ wave 3: [impl, impl] → [spec-review, spec-review] → commit
     └─ final: code-quality-review → finishing-a-development-branch
```

**Git state evolution:**
- Working tree is clean at wave boundaries (between waves).
- Within a wave, implementers make staged changes; controller verifies and commits at boundary.
- No intermediate commits within a wave. One commit per wave. No worktrees. No branch switches.

---

## Error Handling

| Failure mode | Detection | Response |
|---|---|---|
| Two tasks in a wave declare overlapping files | Controller pairwise-disjoint check before dispatch | Split wave into sub-waves; report the split; do NOT dispatch |
| Planner missed a shared-infra file (e.g., two tasks both edit a barrel export) | Controller `## Shared Infrastructure` check before dispatch | Same — split wave |
| Implementer writes outside declared `Files:` | Implementer is supposed to self-report `BLOCKED: scope-expansion`; controller also verifies via `git diff --cached --name-only` at wave commit | If self-reported: split into solo follow-up wave. If caught at commit: unstage, revert scope-violating writes, escalate |
| Implementer uses `git add -A` | Controller's re-stage-from-declared-files step overwrites the stage list at commit time | Extra staged files get caught and escalated |
| Test suite fails at wave boundary with individual task tests passing | Controller runs test suite as wave gate | Bisect by unstaging one task at a time; once offender found, dispatch fix subagent scoped to that task's files |
| Spec reviewer finds issues in one task out of N in a wave | Parallel spec review returns one ❌ | Re-dispatch that single implementer to fix; other tasks stay staged but uncommitted; re-review only the offender |
| Implementer subagent crashes mid-write leaving partial files | Next pre-dispatch `git status` check (clean working tree required) catches it at NEXT wave boundary | Escalate — partial state means we don't know what the half-written files contain; human review required |
| User runs the flow on `main`/`master` | Existing safety check in SADD is unchanged | Stop and require explicit consent (unchanged behavior) |

---

## Testing

**The design itself is tested via a live end-to-end speed-mode execution** against a small plan (5-6 tasks across 2-3 waves) on a throwaway feature branch. Verification criteria:

1. Controller dispatches multiple implementers in a single message within a wave (observable: one controller message containing N `Agent` tool-use blocks).
2. Controller dispatches multiple spec reviewers in a single message after implementers return.
3. `git log --oneline` on the feature branch shows **one commit per wave**, not one per task.
4. `git worktree list` on the repo shows no new worktrees created by the flow.
5. The controller does not execute any `git checkout -b`, `git switch -c`, `git checkout <branch>`, or `git switch <branch>` command at any point.
6. Deliberately injecting an implementer that tries to `git add -A` results in the controller catching the scope violation at wave-commit time.
7. Deliberately authoring a plan with two tasks declaring overlapping `Files:` results in the controller splitting the wave before dispatch, with a visible "wave split" report.
8. On `bonsai-custom` (or any non-main branch), the flow proceeds without the main/master consent prompt. On `main`, the flow stops.

**Regression coverage for existing discipline:**

9. `**Required Skills:**` still loads at controller setup.
10. JIT context7 verification still fires inside implementer prompts.
11. Final code-quality reviewer still runs at feature end.
12. Optional `bonsai-verify-ui` breadcrumb still fires for UI features.
13. `finishing-a-development-branch` handoff is unchanged.

---

## Rollout

Single-PR landing is possible because all edits are interdependent — a plan written in the new format cannot be executed by the old controller, and vice versa. One PR per Tier 2 file would leave the flow in a broken intermediate state.

Suggested commit sequence within one PR (for reviewer sanity):
1. `writing-plans/SKILL.md` + marker + manifest entry
2. `subagent-driven-development/SKILL.md` + marker + manifest entry
3. `subagent-driven-development/implementer-prompt.md` + `spec-reviewer-prompt.md` + marker + manifest entry
4. Rebuild `docs/bonsai/tier-2-edits.md` TOC line
5. Live smoke test on a throwaway feature (not committed to this PR, just reported in the PR description)

No upstream-merge contingency needed beyond the standard "verify marker comments survived" flow in `docs/bonsai/customizing/README.md`.

---

## Open Questions (to resolve before writing-plans)

1. **Wave-boundary test gate cost** — running the full test suite at every wave boundary adds wall-clock time. For a feature with 4 waves, that's 4 full test runs. Alternative: run only the tests affected by the wave's declared files (requires a test-scoping tool the team may not have). Default in this spec: full suite at every wave, to catch cross-wave regressions. Revisit if it becomes the bottleneck.
2. **Default `Shared Infrastructure` list maintenance** — the list in component 1 is a sensible v1 default but will drift. Should it live inline in `writing-plans/SKILL.md` or in a Tier 3 `bonsai-shared-infra-defaults` skill that `writing-plans` references? Inline is simpler for v1; extract when it grows past ~15 entries.
3. **Careful-mode escape hatch** — the `**Flow:** speed-mode` header value implies a `careful-mode` counterpart for production/critical work. Out of scope for this spec; add in a follow-up once speed-mode is proven. The current design works even without careful-mode because the user can manually request per-task reviews.
