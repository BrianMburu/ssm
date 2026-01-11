---
name: task-status
description: Show current task progress and status
---

# Task Status

Display comprehensive status of the current task.

## Step 1: Load Current State

```bash
cat .claude/state/active.md
```

Extract:
- Current Task ID
- Phase and Step
- Blocked status
- Current Focus

## Step 2: Load Task Progress

```bash
TASK_ID=$(grep -A1 "^## Current Task" .claude/state/active.md | tail -1 | xargs)

if [ -d "tasks/$TASK_ID" ]; then
    echo "=== Task: $TASK_ID ==="
    
    # Show progress
    echo ""
    echo "--- Progress ---"
    cat "tasks/$TASK_ID/progress.md"
    
    # Show plan summary
    echo ""
    echo "--- Plan Summary ---"
    head -50 "tasks/$TASK_ID/plan.md"
else
    echo "No active task found."
fi
```

## Step 3: Calculate Completion

Count completed vs total items:

```bash
if [ -f "tasks/$TASK_ID/progress.md" ]; then
    TOTAL=$(grep -c '^\- \[' "tasks/$TASK_ID/progress.md" || echo 0)
    DONE=$(grep -c '^\- \[x\]' "tasks/$TASK_ID/progress.md" || echo 0)
    echo ""
    echo "Completion: $DONE / $TOTAL items"
fi
```

## Step 4: Check for Blockers

```bash
BLOCKED=$(grep "^BLOCKED:" .claude/state/active.md | cut -d':' -f2 | xargs)
if [ "$BLOCKED" = "Yes" ]; then
    echo ""
    echo "⚠️ BLOCKERS DETECTED"
    grep -A10 "^## Blockers" .claude/state/active.md | head -10
fi
```

## Step 5: Show Next Actions

```bash
echo ""
echo "--- Next Steps ---"
grep -A5 "^## Next Steps" .claude/state/active.md | tail -5
```

---

## Status Report Format

Present status in this format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TASK STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: [task-id]
Phase: [phase name] (Step X of Y)
Status: [IN_PROGRESS | BLOCKED | PAUSED]

Progress: ████████░░░░░░░░ 50% (5/10 items)

Current Focus:
→ [current focus from active.md]

Next Steps:
1. [ ] [next step 1]
2. [ ] [next step 2]

Blockers: [None | List blockers]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Commands

After showing status, suggest relevant actions:

- **Continue work**: Just proceed with Current Focus
- **Save progress**: `/save-state`
- **View full plan**: `cat tasks/<task-id>/plan.md`
- **View decisions**: `cat tasks/<task-id>/decisions.md`
- **Mark complete**: Update progress.md checkboxes
