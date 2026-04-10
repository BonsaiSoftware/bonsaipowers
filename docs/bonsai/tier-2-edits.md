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
**Marker:** `<!-- BONSAI TIER-2 EDIT: Step 1 (smoke test) is a team-specific addition not in upstream. On upstream merge, ensure this step survives. -->`
**Commit:** _pending_

**What changed:** Inserted a new checklist step (at position 1, shifting the original steps 1-9 to 2-10) that instructs the agent to invoke the `test-random` skill before any real brainstorming begins and halt if the expected response string is missing. Also added a corresponding node to the DOT flowchart (highlighted `lightyellow` so the Bonsai addition is visually obvious in rendered diagrams).

**Why:** Two reasons. (1) Plug-and-play verification: when a teammate installs `bonsaipowers` and runs their first brainstorm, they get immediate confirmation that the plugin is loaded, skills are discoverable, and the `SessionStart` hook injected `using-superpowers` correctly. A broken install fails loudly on the first real task instead of silently producing degraded brainstorming. (2) Reference implementation: this edit demonstrates the Tier 2 edit pattern (marker comment + manifest entry + flowchart update) for future team members who need to add more invasive orchestration customizations.

**Verification:** In a fresh Claude Code session in any project that has `bonsaipowers` installed, say "brainstorm a new feature". The agent's first action should be to invoke the `test-random` skill and report back `skill-works-abc123` before asking any brainstorming questions. If the agent skips this step, either the Tier 2 edit was lost on merge or the agent is not following the checklist — re-read `skills/brainstorming/SKILL.md:22` and confirm step 1 is present.
