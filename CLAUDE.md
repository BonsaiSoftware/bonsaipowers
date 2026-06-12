# Bonsaipowers — Maintainer Guide

You are working inside **bonsaipowers**, the Bonsai Software fork of obra's [superpowers](https://github.com/obra/superpowers) Claude Code plugin. This repo IS the plugin — team members install it via `/plugin install git+https://github.com/BonsaiSoftware/bonsaipowers.git` and every session in every project inherits the skills, agents, commands, and hooks that live here.

**Your role:** maintainer, not consumer. Upstream's contributor rules ("don't edit plugin files", 94% rejection rate) don't apply here — we are a downstream fork with our own rules, below. Full strategy and rationale: [`docs/bonsai/customizing/README.md`](docs/bonsai/customizing/README.md) (read it for non-trivial changes; this file is the operative short version).

---

## The three-tier skill model

Identify the tier before touching anything in `skills/`.

### Tier 1 — never touch

`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `receiving-code-review`, `requesting-code-review`, `using-git-worktrees`, `writing-skills`

Pressure-tested process discipline; edits cause subtle regressions (skipped reviews, fabricated test passes). Never rename, restructure, or reword — the red-flag tables, hard gates, and "human partner" language are load-bearing. Typo and cross-reference fixes are fine. If you need different behavior, write a Tier 3 skill that narrows the rule for our context.

### Tier 2 — edit deliberately, own the merge cost

`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `finishing-a-development-branch`, `using-superpowers`

These define how work flows through the agent; every edit is a future merge conflict. Rules for every Tier 2 edit:

1. **Prefer Tier 3 first** — only edit Tier 2 when you need a hard guarantee that a step runs (auto-invocation is probabilistic).
2. **Confirm with your human partner** that the edit is intentional before making it.
3. **Mark the edit site:** `<!-- BONSAI TIER-2 EDIT: <short description> -->`.
4. **Document it** in `docs/bonsai/tier-2-edits.md` — index row + full entry.
5. **Run the smoke test** (below) before committing.

### Tier 3 — ours to create freely

`skills/bonsai-*/SKILL.md` — never conflicts on merge. Rules:

1. **`bonsai-` prefix**, active-voice gerund form (`bonsai-reviewing-migrations`).
2. **Description is a trigger, not a summary.** Start with "Use when…"; never describe the workflow (CSO warning — `skills/writing-skills/SKILL.md:154-156`).
3. **Write it test-first** per `writing-skills`: run the pressure scenario against a subagent *without* the skill, capture the rationalizations, write the minimal text that addresses them.
4. **One level of reference files max** — `SKILL.md` + companions in the same directory, never chained.

---

## Composition — how custom skills plug into orchestration

In order of preference:

1. **Auto-invocation (default):** a Tier 3 skill with a precise trigger description fires automatically via the 1%-match rule in `using-superpowers`. No orchestration edit needed.
2. **Explicit invocation (Tier 2 edit):** when a team rule is absolute. Existing examples in `skills/brainstorming/SKILL.md`: step-1 structured codebase recon, step-4 context7 + WebSearch HARD-GATE, step-5 Azure-native preference.

---

## Upstream sync

```bash
git remote add upstream https://github.com/obra/superpowers.git   # once
git fetch upstream
git checkout bonsai-custom
git merge upstream/main
```

Conflicts should appear only in Tier 2 files (Tier 1 we don't edit; Tier 3 upstream doesn't have). Read both sides and keep the Bonsai customization AND the upstream improvement — never accept an upstream change that reverts an intentional edit. Use the **index in `docs/bonsai/tier-2-edits.md`** to verify every marker for a conflicted file survived, then run the smoke test.

## The smoke test

Required after every upstream merge and before committing any skill change. In a fresh session, say "brainstorm a small feature" and confirm the Bonsai Tier 2 behavior fires:

- step 1 is **structured codebase recon** (not upstream's vague "explore project context"),
- step 4 runs **at least one context7 query AND one WebSearch query** before approaches are proposed,
- approach proposals show the **Azure-native preference**.

If upstream behavior leaks through, a Tier 2 edit was lost.

---

## Other rules

1. **Commands** go in `commands/bonsai-<name>.md`, **agents** in `agents/bonsai-<name>.md` — same prefix convention as skills.
2. **Team skills ship from this repo's `skills/`**, never `~/.claude/skills/` (personal scope, doesn't reach the team).
3. **No MCP config in the plugin.** MCPs belong in the consuming project's `.mcp.json` or the user's `~/.claude.json`.
4. **`docs/bonsai/**/research-*.md` are frozen archives** — don't edit their content and don't load them into context during routine work. If the strategy evolves, update `docs/bonsai/customizing/README.md` instead.

---

## Distribution

Team members install with `/plugin install git+https://github.com/BonsaiSoftware/bonsaipowers.git` and update with `/plugin update bonsaipowers`. When shipping significant Tier 2 changes, bump `version` in `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, and `package.json` together and pin a git tag. The `SessionStart` hook (`hooks/session-start`) injects `using-superpowers` into every session automatically — installation is plug-and-play.

---

## When in doubt

- **Strategy:** `docs/bonsai/customizing/README.md` · **How skills load:** `docs/bonsai/how-it-works/README.md`
- **How to write a skill:** `skills/writing-skills/SKILL.md` (Tier 1 — read, don't edit) · **Testing skills:** `skills/writing-skills/testing-skills-with-subagents.md`
- **Tier 2 edit manifest:** `docs/bonsai/tier-2-edits.md` · **Upstream:** https://github.com/obra/superpowers
