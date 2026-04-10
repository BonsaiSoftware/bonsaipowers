# Customizing Bonsaipowers — Fork Maintainer Guide

A practical guide for the Bonsai team on how to extend this plugin with our own skills, wire in MCP servers, and sync with upstream without losing our work.

> **Context shift:** most existing superpowers customization docs online assume you are a *consumer* of obra's upstream plugin and tell you "don't edit plugin files — they'll get clobbered on update." **That advice does not apply here.** We are the plugin. Our fork (`bonsaipowers`) is the source of truth for our team, and `skills/` in this repo is exactly where our custom skills belong. The only cost is merge conflicts when we pull from upstream, and that cost is acceptable.

> **Before reading this:** read [`../how-it-works/README.md`](../how-it-works/README.md) first. You need to understand how skills load and how the SessionStart hook injects `using-superpowers` before any of the strategy makes sense.

---

## Reading order

1. This README — the strategy and playbook for the fork.
2. **[research-customization-locations.md](research-customization-locations.md)** — authoritative "where do files live" map per harness. Still useful for understanding personal vs project vs plugin scope.
3. **[research-custom-skills.md](research-custom-skills.md)** — deep read of `writing-skills` and the exact frontmatter format used by every skill.
4. **[research-mcp.md](research-mcp.md)** — how Claude Code's MCP system works, `.mcp.json` schema, and how skills can call MCP tools.

---

## The strategy — three tiers of skills

We classify every skill in `skills/` into one of three tiers. Each tier has a different rule about whether we're allowed to edit it.

```
┌────────────────────────────────────────────────────────────────────┐
│ TIER 1 — CORE DISCIPLINE SKILLS (never touch)                      │
│   test-driven-development, systematic-debugging,                   │
│   verification-before-completion, receiving-code-review,           │
│   requesting-code-review, using-git-worktrees, writing-skills      │
│                                                                     │
│   These encode hard-won process discipline. Obra has pressure-     │
│   tested them across thousands of agent sessions. Editing them     │
│   produces subtle regressions you won't notice until an agent      │
│   skips a review or fabricates a test pass. Leave them alone.      │
├────────────────────────────────────────────────────────────────────┤
│ TIER 2 — ORCHESTRATION SKILLS (edit when needed)                   │
│   brainstorming, writing-plans, executing-plans,                   │
│   subagent-driven-development, dispatching-parallel-agents,        │
│   finishing-a-development-branch, using-superpowers                │
│                                                                     │
│   These define HOW work flows through the agent. Editing them is   │
│   how we inject our conventions (NestJS patterns, deploy runbook,  │
│   team review checklist) into the default workflow. Touching       │
│   these means we OWN the merge conflict when we pull upstream.     │
│   That's the price of a customized flow.                           │
├────────────────────────────────────────────────────────────────────┤
│ TIER 3 — ADDITIVE SKILLS (ours to create)                          │
│   skills/bonsai-*/SKILL.md                                         │
│                                                                     │
│   New skills we write for our team live here. Prefix them with     │
│   `bonsai-` so they're easy to grep, easy to identify in the       │
│   skill list, and impossible to collide with an upstream skill     │
│   obra might add later. These never conflict on merge because      │
│   upstream doesn't have them.                                      │
└────────────────────────────────────────────────────────────────────┘
```

**Golden rule:** prefer Tier 3 over Tier 2. Only edit an orchestration skill when the behavior you need can't be achieved through auto-invocation of a Tier 3 skill. Every Tier 2 edit is a future merge conflict.

---

## Where things go (fork-maintainer matrix)

| You want to… | Put it here | Notes |
|---|---|---|
| Add a team-wide skill | `skills/bonsai-<name>/SKILL.md` | Use `bonsai-` prefix. Survives upstream merges cleanly. |
| Edit how brainstorming/writing-plans works | `skills/brainstorming/SKILL.md` etc. | You own the merge conflict. Document the edit in the commit message so it survives rebase. |
| Add a team-wide command | `commands/bonsai-<name>.md` | Same prefix convention. |
| Add a team-wide subagent | `agents/bonsai-<name>.md` | Same prefix convention. |
| Add a team MCP server | `.mcp.json` at your project's root (not here) | MCPs are project/user scope, not plugin scope. The plugin ships zero MCP config by design. |
| Personal skill for one dev only | `~/.claude/skills/<name>/SKILL.md` | Stays on that dev's machine, not shared with the team. |
| Project-specific override for one repo | `<project>/CLAUDE.md` | Top of the precedence stack. |
| Edit a core discipline skill (TDD, debugging) | ❌ don't | These are load-bearing. Propose an additive alternative instead. |
| Hand-edit `package.json` or `plugin.json` to rename | ✅ once, at fork setup time | See "Forking checklist" below. |

---

## Part 1 — Adding a new skill (the Tier 3 path)

This is the default path. 90% of what our team wants to add belongs here.

### 1.1 Example: `skills/test-random/`

We ship a trivial example skill at `skills/test-random/SKILL.md` to verify the plugin is loaded and skills are discoverable:

```markdown
---
name: test-random
description: Returns a test string. Use when the user says "test random", "test string", or "/test-random".
---

Reply to the user with exactly this:

**Test string:** `skill-works-abc123`
```

Trigger it from any session after installing the plugin by saying `test random`. If Claude responds with the exact test string, the plugin is wired up correctly. If not, check that the SessionStart hook ran and the skill directory is discoverable.

(This one kept its original name rather than `bonsai-test-random` — it predates the prefix convention. New skills should use the prefix.)

### 1.2 The frontmatter — two fields, strict rules

```yaml
---
name: bonsai-my-skill
description: Use when <specific triggering condition>, before <action>
---
```

- **Only `name` and `description`.** No `type`, `version`, `tags`, `model`. Max 1024 characters total.
- **`name`:** letters, numbers, hyphens only. Prefix with `bonsai-`. Use active-voice gerunds where possible — `bonsai-reviewing-migrations`, not `bonsai-migration-reviewer`.
- **`description`:** third person, starts with "Use when…", describes **only triggering conditions**, never summarizes what the skill does.

**The CSO warning** (from `writing-skills/SKILL.md:154-156`):

> "When a description summarizes the skill's workflow, Claude may follow the description instead of reading the full skill content. A description saying 'code review between tasks' caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO reviews."

If you put the workflow in the description, agents will skip reading the body. Descriptions are discovery metadata, not documentation.

### 1.3 How composition with brainstorming/writing-plans works

A well-written Tier 3 skill gets auto-invoked during brainstorming and writing-plans **without any edit to those skills**. The mechanism is the 1%-match rule in `using-superpowers`: every turn, the agent scans all skill descriptions, and if a skill's description matches the current situation (even loosely), it invokes the skill.

So a skill with this description:

```yaml
description: Use when proposing architecture approaches for a NestJS backend feature, before finalizing the design
```

will automatically fire during brainstorming's "Propose 2-3 approaches" step when the feature happens to be a NestJS backend. Brainstorming doesn't need to know the skill exists.

**This is the preferred path.** Write skills with precise trigger descriptions and let auto-invocation do the wiring.

### 1.4 When auto-invocation isn't enough — edit orchestration skills (Tier 2)

Sometimes a team rule is absolute (e.g., "every brainstorm for a backend feature must reference our NestJS conventions, no exceptions"). Auto-invocation is probabilistic — 1%-match is strong but not a hard guarantee. For hard guarantees, edit the orchestration skill itself.

**Pattern:** add a named step to the skill's checklist that explicitly references your Tier 3 skill.

Example edit to `skills/brainstorming/SKILL.md`:

```markdown
## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits
2. **Invoke `bonsai-identify-domain`** — determine whether this is NestJS backend, React frontend, or infra work
3. **Offer visual companion** ...
```

And a corresponding edit to mention the team skill in the "Propose 2-3 approaches" section. This guarantees the skill runs every time, at the cost of: (a) owning the merge conflict when upstream edits brainstorming and (b) needing to re-read the file after every upstream merge to confirm your edit survived.

**Track every Tier 2 edit** in a file (see `docs/bonsai/tier-2-edits.md` if it exists — create it if not) so a future merge-conflict resolution has a manifest to check against.

---

## Part 2 — Upstream sync workflow

Living with upstream means we need a repeatable process for pulling changes.

```bash
# Add upstream once, if not already
git remote add upstream https://github.com/obra/superpowers.git

# Sync
git fetch upstream
git checkout bonsai-custom
git merge upstream/main

# Resolve conflicts — expect them in Tier 2 files
# Do NOT expect conflicts in Tier 3 files (bonsai-*)
# Do NOT accept upstream changes that revert a Tier 2 edit you intentionally made

# Re-run the smoke test
# In a fresh session: say "test random" and verify the response
```

**Conflict strategy by tier:**

- **Tier 1 conflicts:** almost never happen (we don't edit them). If one does, take upstream's version wholesale.
- **Tier 2 conflicts:** read both versions carefully. Keep your team customization AND whatever upstream improved. This is where the merge cost lives.
- **Tier 3 conflicts:** should not happen. If one does, something is wrong — upstream doesn't have `bonsai-*` skills.

**After every merge:** do a skill-list smoke test by opening a session and confirming `test-random` still responds with the expected string. If it doesn't, the plugin is broken and the team will hit it before you do.

---

## Part 3 — MCP servers

MCPs and skills are independent systems. This plugin ships **zero** MCP configuration, same as upstream. Team members configure MCPs in their own project's `.mcp.json` or user-level `~/.claude.json`.

See [research-mcp.md](research-mcp.md) for the full schema and precedence model. The two things worth knowing at the plugin level:

1. **Don't add MCP config to the plugin.** It's not the right scope — MCPs belong to projects (teams check `.mcp.json` into the repo that needs them) or to users (personal tools like Figma). Putting them here would force every project to inherit them.
2. **A skill can call an MCP tool by name.** If `bonsai-reviewing-migrations/SKILL.md` tells the agent to call `mcp__internal-db__query_row_count`, and that MCP is configured in the consuming project, the tool call just works. If the MCP isn't configured, the tool call fails loudly — which is the right failure mode.

---

## Part 4 — Distributing to the team

Team members install the plugin via git URL:

```
/plugin install git+https://github.com/bonsai-team/bonsaipowers.git
```

Or via a private marketplace entry if we set one up. The plugin's `SessionStart` hook automatically injects `using-superpowers` on every session, so from the team member's perspective it's plug-and-play: they install once and every future session knows about our skills.

**Version pinning:** for stability, team members can pin to a specific commit SHA or git tag. When we ship a significant change to Tier 2 skills, bump the version in `.claude-plugin/plugin.json` and `package.json` and tell the team to re-run `/plugin update bonsaipowers`.

---

## Part 5 — Anti-patterns (things that look reasonable but aren't)

1. **Editing a Tier 1 skill.** It's load-bearing and pressure-tested. If you think you need to, write a Tier 3 counterpart that narrows the Tier 1 rule for your context.
2. **Summarizing a skill's workflow in its `description`.** The agent will follow the description and skip reading the body. Descriptions are discovery metadata only.
3. **Writing a Tier 3 skill without a failing baseline test.** You don't know what you're preventing. Run the pressure scenario first, capture the failure, then write the skill.
4. **Adding MCP config to the plugin.** Wrong scope. MCPs go in the consuming project's `.mcp.json` or the user's `~/.claude.json`.
5. **Making a Tier 2 edit without documenting it.** Your future self (or a teammate) will resolve a merge conflict and not know which side is intentional. Keep a manifest.
6. **Forgetting the smoke test after a merge.** The `test-random` skill exists for exactly this reason. Use it.
7. **Skipping the `bonsai-` prefix on new skills.** Sooner or later obra ships a skill with the same name and you get a silent collision.

---

## Forking checklist (one-time setup, for reference)

If you're setting up a new fork of the plugin from scratch:

- [ ] Rename `.claude-plugin/plugin.json` `"name"` field to your team name
- [ ] Update `homepage` and `repository` fields to your team's repo URL
- [ ] Rename `package.json` `"name"` field to match
- [ ] Grep for hardcoded "superpowers" references in `hooks/` and update as needed
- [ ] Add `upstream` remote pointing at `https://github.com/obra/superpowers.git`
- [ ] Add the test-random skill (or keep the existing one) as your smoke test
- [ ] Write the first real team skill as a Tier 3 `bonsai-*` skill to validate the flow
- [ ] Install the plugin in a test session and run the smoke test

---

## Further reading

- **Canonical skill-authoring guide:** `skills/writing-skills/SKILL.md` (read in full before writing any Tier 3 skill)
- **Skill testing methodology:** `skills/writing-skills/testing-skills-with-subagents.md`
- **Persuasion principles:** `skills/writing-skills/persuasion-principles.md`
- **Session-start loading mechanics:** [`../how-it-works/README.md`](../how-it-works/README.md)
- **Official MCP docs:** https://docs.claude.com/en/docs/claude-code/mcp
- **Official plugin docs:** https://docs.claude.com/en/docs/claude-code/plugins
