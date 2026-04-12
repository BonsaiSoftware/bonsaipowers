---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed
5. Read **Required Skills:** from the plan header and invoke each listed skill (e.g. `nestjs-best-practices`, `owasp-security`). These are active constraints for the entire execution — not optional. If a listed skill can't be found, STOP and tell the user.

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

**Just-in-time API verification:**
If a task step references a library API and you're not sure of the exact signature or behavior:
- One context7 query to verify before writing the code
- Do NOT guess from training data when the plan already pinned a version
- Do NOT research alternatives — the plan already decided the approach
- This is verification, not research. The plan says `verifyAsync({ algorithms: ['RS256'] })`, you confirm that's the right signature for `@nestjs/jwt@11.0`, then write it.

**Security gates (from loaded owasp-security skill):**
If a task step has OWASP constraints (marked with `⚠` or explicit "MUST" requirements):
- Implement EXACTLY as specified — these are requirements, not suggestions
- If you can't satisfy the constraint, STOP and ask — do not skip it, do not weaken it
- The verification step for that task must confirm the constraint is met
- Example: "MUST use parameterized queries" means you write parameterized queries, you test that they're parameterized, you don't move on until they are

**Best-practices compliance (from loaded skills):**
If a required skill is loaded (e.g. `nestjs-best-practices`):
- Follow its patterns when writing implementation code
- If the plan contradicts a best-practice, follow the plan — the planner already made that tradeoff
- If the plan is silent on something the skill covers, follow the skill
- This is pattern compliance, not research — don't read reference files "just in case", only when the code you're writing falls under a rule

<!-- BONSAI TIER-2 EDIT: Step 1 item 5 (required skill loading) and Step 2 execution constraints (JIT context7 verification, OWASP security gates, best-practices compliance) are team-specific additions not in upstream. On upstream merge, ensure Step 1 keeps the skill-loading item and Step 2 keeps all three constraint sub-sections before Step 3. -->

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
