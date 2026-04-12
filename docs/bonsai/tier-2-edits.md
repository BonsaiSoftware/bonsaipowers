# Tier 2 Edits Manifest

Every intentional edit to a Tier 2 (orchestration) skill in this fork. Used as the authoritative reference during upstream merges — if a conflict hides or reverts an entry in this file, the resolution is wrong.

**What belongs here:** edits to files in `skills/brainstorming/`, `skills/writing-plans/`, `skills/executing-plans/`, `skills/subagent-driven-development/`, `skills/dispatching-parallel-agents/`, `skills/finishing-a-development-branch/`, `skills/using-superpowers/`.

**What does NOT belong here:** additive `bonsai-*` skills (Tier 3, track in git only), personal `~/.claude/` customizations, project-level `CLAUDE.md` overrides in consuming repos.

**On upstream merge:** walk this file top to bottom. For each entry, open the edited file, find the marker comment (`<!-- BONSAI TIER-2 EDIT: ... -->`), and verify the described change is still present after the merge resolution.

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

### 2026-04-10 — brainstorming: add `test-random` smoke test as step 1

**File:** `skills/brainstorming/SKILL.md`
**Marker:** `<!-- BONSAI TIER-2 EDIT: Step 1 (smoke test), step 2 (structured codebase recon additions), and step 5 (research unknowns via context7 + WebSearch) are team-specific additions not in upstream. On upstream merge, ensure these steps survive and the numbering stays consistent (upstream has no step 1 and no step 5; its steps 1-9 map to our 2-4, 6-11 with step 2 upgraded). -->`
**Commit:** _pending_

**What changed:** Inserted a new checklist step (at position 1, shifting the original steps 1-9 to 2-10) that instructs the agent to invoke the `test-random` skill before any real brainstorming begins and halt if the expected response string is missing. Also added a corresponding node to the DOT flowchart (highlighted `lightyellow` so the Bonsai addition is visually obvious in rendered diagrams).

**Why:** Two reasons. (1) Plug-and-play verification: when a teammate installs `bonsaipowers` and runs their first brainstorm, they get immediate confirmation that the plugin is loaded, skills are discoverable, and the `SessionStart` hook injected `using-superpowers` correctly. A broken install fails loudly on the first real task instead of silently producing degraded brainstorming. (2) Reference implementation: this edit demonstrates the Tier 2 edit pattern (marker comment + manifest entry + flowchart update) for future team members who need to add more invasive orchestration customizations.

**Verification:** In a fresh Claude Code session in any project that has `bonsaipowers` installed, say "brainstorm a new feature". The agent's first action should be to invoke the `test-random` skill and report back `skill-works-abc123` before asking any brainstorming questions. If the agent skips this step, either the Tier 2 edit was lost on merge or the agent is not following the checklist — re-read `skills/brainstorming/SKILL.md:22` and confirm step 1 is present.

---

### 2026-04-10 — brainstorming: upgrade step 2 (structured codebase recon) + insert step 5 (research unknowns)

**File:** `skills/brainstorming/SKILL.md`
**Marker:** Shared with the smoke-test edit above — single `<!-- BONSAI TIER-2 EDIT -->` comment covering all three Bonsai additions (smoke test, recon upgrade, research step).
**Commit:** _pending_

**What changed:** Two related additions to the brainstorming checklist and its accompanying DOT flowchart and Process-section prose:

1. **Step 2 upgraded** from generic "Explore project context — check files, docs, recent commits" to "Structured codebase recon": check files/docs/commits PLUS grep the dependency manifest for existing libraries, scan the nearest `CLAUDE.md` for project conventions, find the most similar existing feature and read how it's structured. The rationale is baked into the step ("proposing Redux when the repo is Zustand wastes everyone's time"). DOT node recolored to `lightyellow` to mark the Bonsai edit.
2. **Step 5 inserted** between "Ask clarifying questions" (step 4) and "Propose 2-3 approaches" (was 5, now 6). The new step, "Research unknowns", is a conditional research gate that leans toward doing the research — it is skipped only for very small tweaks or obviously-familiar territory. It directs the agent to use two tools with specific granularity constraints:
   - **context7** for API/library feasibility spot-checks at yes/no granularity ("does NestJS support WebSocket + guards on the same decorator?"), one query per uncertain question. Implementation details are explicitly out of scope — those belong in writing-plans.
   - **WebSearch** for prior-art scans on problems with well-trodden solutions ("how do teams typically implement multi-tenant row-level security in Postgres 16?"), one well-framed query rather than several shotgun searches. Results feed the approach proposal directly.
   Downstream effects: step 6 ("Propose 2-3 approaches") now explicitly says approaches ruled out by the research step are off the table and approaches surfaced by it are on it. A new "Researching unknowns (before proposing approaches)" subsection was added to the Process body (right before "Exploring approaches") with the full guidance on when to use each tool and what NOT to research. The DOT flowchart gained a `Research unknowns\n(context7 + WebSearch)` node (lightyellow) between clarifying questions and approach proposal.

Steps 5-10 from the previous version were renumbered to 6-11 and the final count is now 11 checklist items.

**Why:** Two pain points the team has hit repeatedly. (1) Approach proposals that don't fit the repo: the agent proposes an approach using a library the project isn't using, or contradicting a convention written down in `CLAUDE.md` that the agent never read. The upgraded step 2 forces a targeted recon (dependency manifest + `CLAUDE.md` + similar feature) instead of a vague "check files, docs, recent commits" that the agent can rationalize skipping. (2) Approach proposals that ignore well-trodden solutions or include ones that aren't actually feasible in the chosen framework: either the agent didn't know about a standard pattern because its training data is stale, or it assumed a framework supports something it doesn't and proposed an approach that falls over during planning. The new step 5 gives the agent two targeted external tools with explicit granularity — yes/no feasibility questions for context7, prior-art scans for WebSearch — and tells it to lean toward using them. Skipping the step is permitted only for very small tweaks, to avoid adding ceremony to trivial brainstorms.

**Verification:** In a fresh Claude Code session, run a brainstorm for a non-trivial feature that touches an unfamiliar library or domain. The agent should: (a) in step 2, grep `package.json`/equivalent and read `CLAUDE.md` before asking clarifying questions, (b) after clarifying questions but before proposing approaches, do at least one `context7` query or `WebSearch` call (or explicitly state why it is skipping — which should only happen for very small tweaks), (c) reference what it learned from that research when presenting the 2-3 approaches. For a trivially small brainstorm (e.g., "add a new enum value"), the agent may skip step 5 entirely; confirm it at least considered the step rather than silently dropping it. If the agent skips the research step on a non-trivial brainstorm without justification, re-read `skills/brainstorming/SKILL.md:27-29` (step 5 text) and the "Researching unknowns" subsection in the Process body, and confirm both survived the most recent upstream merge.
