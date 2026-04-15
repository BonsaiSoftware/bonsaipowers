# Customizations Made to Bonsaipowers

A manifest of all modifications to the fork, organized by skill and type. For the full Tier 2 edit details (what/why/verification), see [`../tier-2-edits.md`](../tier-2-edits.md).

---

## Tier 2 Edits (orchestration skill modifications)

### brainstorming (2026-04-10, research step hardened 2026-04-12/13, smoke test removed 2026-04-15)

**File:** `skills/brainstorming/SKILL.md`

Two additions to the brainstorming checklist and flow (numbering reflects the current 10-step checklist after the 2026-04-15 smoke-test removal):

1. **Step 1: Structured codebase recon** (upgraded from generic "Explore project context") — now requires targeted scanning: grep dependency manifests for existing libraries, scan `CLAUDE.md` for conventions, read the most similar existing feature. Ensures approach proposals fit what's already in the repo.

2. **Step 4: Research unknowns** (new step, between clarifying questions and approach proposal) — mandatory research step gated on a HARD-GATE (added 2026-04-12 for context7, 2026-04-13 for WebSearch). Uses:
   - **context7** for API feasibility spot-checks (yes/no granularity) — at least one query required
   - **WebSearch** for prior-art scans (well-framed queries, not shotgun searches) — at least one query required
   - Skip is only permitted for pure internal refactors or config-only tweaks with zero external dependencies

3. **Step 5: Azure-native preference in approach proposals** (added 2026-04-12) — when a feature involves cloud infrastructure, storage, auth, messaging, or any service Azure provides natively, the agent must include the Azure-native option and recommend it by default.

DOT flowchart updated with `lightyellow` nodes for all Bonsai additions.

A prior step 1 (`test-random` plugin smoke test) was removed on 2026-04-15 — it served its introductory purpose and the friction of running a no-op skill on every brainstorm outweighed the diagnostic value. See the corresponding entry in `../tier-2-edits.md`.

### writing-plans (2026-04-12)

**File:** `skills/writing-plans/SKILL.md`

Research section + plan header update:

1. **`## Research (before writing tasks)` section** (between Scope Check and File Structure) — six numbered research sub-steps the planner runs before designing file structure:
   - Resolve current APIs via **context7** (pin versions, get actual method signatures)
   - Load **best-practices skills** conditional on detected stack (nestjs-best-practices, vercel-react-best-practices)
   - Pull **OWASP security constraints** via owasp-security (hard requirements, not footnotes)
   - **Don't-hand-roll check** (query context7 for existing libraries before writing "build X" tasks)
   - **Pitfall scan** (context7/WebSearch for common mistakes per library)
   - **microsoft-docs** (conditional on Azure/Microsoft services)

2. **`## How Research Flows Into the Plan` mapping table** — shows where each research finding embeds (library version -> Tech Stack header, OWASP constraint -> task step, pitfall -> warning line, etc.)

3. **Updated Plan Document Header** — added `**Required Skills:**` field and updated `**Tech Stack:**` to specify pinned versions from research.

### executing-plans (2026-04-12)

**File:** `skills/executing-plans/SKILL.md`

Skill loading + execution constraints:

1. **Step 1 item 5** — reads `**Required Skills:**` from the plan header and invokes each skill. These become active constraints. Stops if a skill can't be found.

2. **Step 2 execution constraints** (three sub-sections between per-task list and Step 3):
   - **Just-in-time API verification** — one context7 query to verify an API signature before writing it. Verification, not research.
   - **Security gates** — implement OWASP constraints exactly as specified. STOP if can't satisfy.
   - **Best-practices compliance** — follow loaded skills when writing code. Plan wins on conflicts; skill fills gaps.

### subagent-driven-development (2026-04-12)

**Files:**
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/spec-reviewer-prompt.md`

Same constraints as executing-plans, adapted for the subagent dispatch model:

1. **SKILL.md — `## Controller Setup` section** — controller loads required skills during initial setup, includes skill names in implementer prompts, includes OWASP constraints in spec reviewer prompts. DOT flowchart updated.

2. **implementer-prompt.md** — three template additions:
   - `## Required Skills` section (controller fills in from plan header, implementer loads them)
   - `## Execution Constraints` section (JIT context7 verification, security gates, best-practices compliance)

3. **spec-reviewer-prompt.md** — `Security constraint verification` sub-section. Reviewer verifies each OWASP constraint is actually implemented in code. A missing/weakened security constraint is a spec failure.

---

## Tier 3 Skills (additive, no merge conflicts)

| Skill | Purpose |
|---|---|
| `nestjs-best-practices` | NestJS production patterns (10 categories, selective reading) |
| `vercel-react-best-practices` | React/Next.js performance optimization from Vercel Engineering |
| `owasp-security` | OWASP Top 10 2025 security patterns for React, Node.js, Azure |

Note: `nestjs-best-practices`, `vercel-react-best-practices`, and `owasp-security` predate the `bonsai-` prefix convention. They are kept as-is for continuity.

---

## The research-to-execution pipeline

These customizations create a pipeline where research findings flow from brainstorming through planning into execution:

```
brainstorming                    writing-plans                     executing-plans / subagent-driven
─────────────                    ─────────────                     ────────────────────────────────
Step 5: Research unknowns        Research (before writing tasks)   Step 1: Load Required Skills
  context7: feasibility            context7: pin versions            Invoke each listed skill
  WebSearch: prior-art             Best-practices: load skills       
                                   OWASP: embed constraints        Step 2: Execute with constraints
                                   Don't-hand-roll: check libs       context7: verify signatures
                                   Pitfalls: scan gotchas             OWASP: implement exactly
                                   microsoft-docs: Azure samples      Best-practices: follow patterns
                                                                    
                                 Plan header carries forward:       Spec reviewer verifies:
                                   **Tech Stack:** (pinned)           Security constraints met
                                   **Required Skills:** (loaded)      (subagent-driven only)
```

**Key principle:** research narrows as it flows downstream. Brainstorming explores ("does X support Y?"). Planning pins ("X v11.0, method signature is..."). Execution verifies ("is this still the right signature?") and complies ("implement this OWASP constraint exactly"). The executor is disciplined, not curious.

---

## Reference

- **Tier 2 edit details:** [`../tier-2-edits.md`](../tier-2-edits.md) — full what/why/verification for each edit
- **Fork strategy:** [`README.md`](README.md) — three-tier model, upstream sync, anti-patterns
- **Skill authoring:** `skills/writing-skills/SKILL.md` ��� how to write new Tier 3 skills
