---
name: continue-task
description: Continue work on the current task from saved session state
---

# Continue Task Work

Load saved state and continue where you left off.

## Step 1: Load Active State

Read the current state file:

```bash
cat .claude/state/active.md
```

Key information to extract:
- **Current Task**: Which task directory to reference
- **Phase/Step**: Where in the implementation plan
- **Last Action**: What was just completed
- **Current Focus**: Immediate next action
- **Immediate Context**: Files to load

## Step 2: Load Task Context (If Applicable)

If a task is active, load its context. **Read the Design Contract and decisions
BEFORE writing any code** — they are the binding implementation strategy and are
the difference between resuming on-design and drifting:

```bash
# Implementation strategy (binding) + full plan
cat tasks/<task-id>/plan.md      # pay special attention to "## Design Contract"

# Decisions and their rationale (NOT optional — read these)
cat tasks/<task-id>/decisions.md 2>/dev/null || echo "No decisions file yet"

# Progress (source of truth for what's done)
cat tasks/<task-id>/progress.md
```

The SessionStart hook already surfaces a digest of the Design Contract, but
re-read the full `plan.md` and `decisions.md` so you hold the complete design,
not just the digest.

## Step 3: Load Recommended Files

Based on "Immediate Context" section, load the listed files.

**Token-Conscious Loading**:
- Only load files listed in "Immediate Context"
- Check context-registry.md for token estimates
- Avoid loading "Do NOT Load" files

## Step 4: Review and Confirm

Before proceeding, verify:

1. ✅ Task and phase are clear
2. ✅ Current focus matches your intent
3. ✅ Necessary files are loaded
4. ✅ No blocking issues

## Step 5: Continue Work

Proceed with the action described in "Current Focus".

---

## Quick Resume Checklist

```
[ ] Read .claude/state/active.md
[ ] Read plan.md Design Contract + decisions.md (binding strategy)
[ ] Load task plan and progress
[ ] Load immediate context files
[ ] Confirm current focus
[ ] Begin work
```

## If State is Stale

If the state doesn't match your intent:

1. Update `.claude/state/active.md` with correct information
2. Or use `/new-task <name>` to start fresh task
3. Then resume normally

## If Starting Fresh Day

After a longer break:

1. Run `/continue-task` to load state
2. Review task progress
3. Verify the plan is still appropriate
4. Update state if priorities changed
5. Continue from current focus
