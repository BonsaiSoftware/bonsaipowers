# Bonsaipowers — Maintainer Guide

You are working inside **bonsaipowers**, the Bonsai Software fork of obra's [superpowers](https://github.com/obra/superpowers) Claude Code plugin. This repo IS the plugin — team members install it via `/plugin install git+https://github.com/BonsaiSoftware/bonsaipowers.git` and every session in every project inherits the skills, agents, commands, and hooks that live here.

**Your role when editing this repo:** you are a maintainer, not a consumer. The upstream superpowers contributor rules (94% rejection rate, "don't edit plugin files") do not apply here — those are about submitting PRs to obra's repo. We are a downstream fork with our own rules, documented below.

**Full strategy:** read [`docs/bonsai/customizing/README.md`](docs/bonsai/customizing/README.md) before making any non-trivial change. It has the three-tier model, the upstream sync workflow, and the anti-patterns. This file is the short version.

---

## The three-tier skill model

Every file in `skills/` falls into one of three tiers. The rules differ by tier.

### Tier 1 — Core discipline skills (never touch)

- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`
- `receiving-code-review`
- `requesting-code-review`
- `using-git-worktrees`
- `writing-skills`

These encode pressure-tested process discipline. Obra has tuned them across thousands of real agent sessions. Editing them produces subtle regressions (agents skip reviews, fabricate test passes, rationalize around checks) that you won't notice until production bites. **Leave them alone.** If you think you need to change a Tier 1 skill, write a Tier 3 skill that narrows it for our context instead.

### Tier 2 — Orchestration skills (edit deliberately, own the merge cost)

- `brainstorming`
- `writing-plans`
- `executing-plans`
- `subagent-driven-development`
- `dispatching-parallel-agents`
- `finishing-a-development-branch`
- `using-superpowers`

These define how work flows through the agent. Editing them is how we inject Bonsai conventions into the default workflow when auto-invocation isn't enough. Every Tier 2 edit is a future merge conflict when we pull from upstream.

**Rules for Tier 2 edits:**

1. **Prefer Tier 3 first.** If a well-described Tier 3 skill can do the job via auto-invocation, use that instead. Only touch Tier 2 when you need a hard guarantee that a step runs.
2. **Mark the edit.** Leave an HTML comment marker at the edit site: `<!-- BONSAI TIER-2 EDIT: <short description> -->`. Merge-conflict resolution will need to know which side of a diff is the intentional Bonsai change.
3. **Document the edit.** When the Tier 2 edits manifest (`docs/bonsai/tier-2-edits.md`) exists, add an entry for every edit. If it doesn't exist yet, create it on your second Tier 2 edit.
4. **Test the edit in a fresh session.** Tier 2 skills are orchestration — a bad edit can derail every brainstorm or plan on the team. Run at least one real end-to-end flow (a real brainstorm or plan execution) before committing.

### Tier 3 — Additive skills (ours to create freely)

- `skills/bonsai-*/SKILL.md`

New team skills live here. Prefix every new skill with `bonsai-` so it's easy to grep, easy to recognize in the skill list, and impossible to collide with an upstream skill obra might add later. Tier 3 skills never conflict on merge.

**Rules for new Tier 3 skills:**

1. **Name with `bonsai-` prefix.** `bonsai-reviewing-migrations`, `bonsai-nestjs-conventions`, `bonsai-deploy-runbook`. Active-voice gerund form where possible.
2. **Description is a trigger, not a summary.** Start with "Use when…". Describe only the conditions under which the skill should fire. Do NOT summarize what the skill does (the CSO warning — see `skills/writing-skills/SKILL.md:154-156`).
3. **Write it test-first.** Follow the iron law in `superpowers:writing-skills`: run the pressure scenario against a subagent *without* the skill loaded, capture the exact rationalizations, then write the minimal skill text that addresses those failures. Skills written from intuition fail at session time.
4. **One level of reference files max.** `SKILL.md` + optional companion files in the same directory. Never chain references.

---

## Composition — how custom skills plug into brainstorming and writing-plans

Two mechanisms, in order of preference:

**1. Auto-invocation (default).** A Tier 3 skill with a precise trigger description gets pulled into brainstorming, writing-plans, or any other orchestration skill *automatically* via the 1%-match rule in `using-superpowers`. No edit to the orchestration skill is needed. Write the description well and the mechanism does the wiring for you.

**2. Explicit invocation (Tier 2 edit).** If a team rule is absolute and can't tolerate auto-invocation's probabilistic nature, edit the orchestration skill directly. The brainstorming checklist has several Tier 2 edits as examples: the step-1 structured codebase recon, the step-4 context7 + WebSearch HARD-GATE research block, and the Azure-native preference in step 5. See `skills/brainstorming/SKILL.md` and its `<!-- BONSAI TIER-2 EDIT -->` marker.

---

## Upstream sync workflow

```bash
# One-time setup
git remote add upstream https://github.com/obra/superpowers.git

# Each sync
git fetch upstream
git checkout bonsai-custom
git merge upstream/main
# Resolve conflicts — expect them in Tier 2 files only
# Never accept an upstream change that reverts an intentional Bonsai edit
# Check every `<!-- BONSAI TIER-2 EDIT -->` marker survived

# Smoke test in a fresh Claude Code session
# Say "brainstorm a small feature" — the first step of the checklist should be
# "Structured codebase recon" (step 1), and the research step (step 4) should
# run at least one context7 query AND one WebSearch query before proposing
# approaches. If upstream behavior leaks through instead, a Tier 2 edit was lost.
```

**Conflict expectations by tier:** Tier 1 almost never conflicts (we don't edit those). Tier 2 is where the merge cost lives — read both versions carefully and keep both our customization and any upstream improvement. Tier 3 should never conflict because upstream doesn't have `bonsai-*` skills.

---

## Rules for agents working in this repo

When you are editing this repo (adding skills, fixing bugs, updating docs), follow these:

1. **Read the tier classification first.** Before touching any file in `skills/`, identify which tier it belongs to. If Tier 1, stop. If Tier 2, confirm with your human partner that the edit is intentional before making it. If Tier 3, proceed.
2. **Never rename, restructure, or reformat Tier 1 skills.** The wording of red-flag tables, rationalization lists, hard gates, and "human partner" language in those skills is load-bearing and was extensively pressure-tested. Surface-level cleanups (fixing typos, updating cross-references) are fine; rewording is not.
3. **Tier 3 skills go in `skills/bonsai-<name>/SKILL.md`.** Do not put them in `~/.claude/skills/` — that's personal-scope and won't ship to the team. The plugin's `skills/` directory is the team-scope location.
4. **Commands go in `commands/bonsai-<name>.md`.** Same prefix convention as skills.
5. **Agents go in `agents/bonsai-<name>.md`.** Same prefix convention.
6. **Do not add MCP configuration to the plugin.** MCPs belong in the consuming project's `.mcp.json` or the user's `~/.claude.json`. The plugin ships zero MCP config, same as upstream.
7. **Smoke test before committing any skill change.** Run a real brainstorm or plan in a fresh session and confirm the Bonsai-specific behavior (structured codebase recon at step 1, context7 + WebSearch HARD-GATE at step 4, Azure-native preference in approach proposals) still fires.
8. **Do not edit files under `docs/bonsai/customizing/research-*.md`.** Those are frozen research notes from when the fork was designed. Update `docs/bonsai/customizing/README.md` instead if the strategy evolves.

---

## Distribution to the team

Team members install with:

```
/plugin install git+https://github.com/BonsaiSoftware/bonsaipowers.git
```

To update, they run `/plugin update bonsaipowers`. For stability, pin to a git tag when shipping significant Tier 2 changes — bump the `version` field in `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, and `package.json` together.

The plugin's `SessionStart` hook (at `hooks/session-start`) injects the `using-superpowers` skill content into every session automatically, so from the team member's perspective installing the plugin is plug-and-play.

---

## When in doubt

- **Strategy questions:** `docs/bonsai/customizing/README.md`
- **How skills load:** `docs/bonsai/how-it-works/README.md`
- **How to write a skill:** `skills/writing-skills/SKILL.md` (Tier 1 — read, don't edit)
- **Skill test methodology:** `skills/writing-skills/testing-skills-with-subagents.md`
- **Upstream we're tracking:** https://github.com/obra/superpowers

