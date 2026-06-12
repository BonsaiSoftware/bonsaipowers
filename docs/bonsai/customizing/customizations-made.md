# Customizations Made to Bonsaipowers

A manifest of all modifications to the fork, organized by type. For Tier 2 edits, [`../tier-2-edits.md`](../tier-2-edits.md) is the **single source of truth** — details are deliberately not duplicated here.

---

## Tier 2 Edits (orchestration skill modifications)

See the index table at the top of [`../tier-2-edits.md`](../tier-2-edits.md) for the full list with dates and per-edit what/why/verification entries. Files touched, at a glance:

- `skills/brainstorming/SKILL.md` — structured codebase recon (step 1), research-unknowns HARD-GATE with context7 + WebSearch (step 4), Azure-native preference (step 5)
- `skills/writing-plans/SKILL.md` — Research section, research→plan mapping table, plan header fields, speed-mode plan format
- `skills/executing-plans/SKILL.md` — required-skills loading + execution constraints (JIT context7 verification, security gates, best-practices compliance)
- `skills/subagent-driven-development/` (SKILL.md + implementer/spec-reviewer prompts) — skill loading, execution constraints, OWASP verification, wave-based parallel dispatch, scoped reviews

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
