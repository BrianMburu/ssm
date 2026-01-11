---
name: ssm-status
description: Show SSM status including task progress and state summary (use built-in /context for context usage)
---

# SSM Status Check

Shows current Session State Manager status. For context window usage, use the **built-in `/context` command**.

## Built-in Commands to Use First

| Command | Purpose |
|---------|---------|
| `/context` | **Use this** - Shows context usage as colored grid |
| `/todos` | Shows TODO/FIXME items in code |
| `/cost` | Shows token usage statistics |

## SSM-Specific Status

Check the files currently loaded and estimate their token usage:

```bash
# List recently accessed files in this session
# This is an estimate based on typical patterns

echo "=== Context Estimation ==="
echo ""

# Check state files (always loaded)
echo "State Files:"
./.claude/scripts/context-size.sh .claude/state/

# Check if task is active
TASK_ID=$(grep -A1 "^## Current Task" .claude/state/active.md 2>/dev/null | tail -1 | xargs)
if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "none" ] && [ -d "tasks/$TASK_ID" ]; then
    echo ""
    echo "Task Files (tasks/$TASK_ID):"
    ./.claude/scripts/context-size.sh "tasks/$TASK_ID"
fi
```

## Step 2: Check Warning Level

Based on current context percentage, determine status:

| Level | Percentage | Recommendation |
|-------|------------|----------------|
| 🟢 Green | < 60% | Normal operation, continue working |
| 🟡 Yellow | 60-70% | Be mindful of what you load next |
| 🟠 Orange | 70-80% | Finish current step, then save + clear |
| 🔴 Red | 80-90% | Save state immediately |
| ⚫ Critical | > 90% | Emergency - save now before auto-compact |

## Step 3: Recommendations

Based on current state, provide specific recommendations:

### If Context is Low (< 60%)
- Continue working normally
- Feel free to load additional reference files
- Consider staying focused on current task

### If Context is Medium (60-80%)
- Avoid loading large files unnecessarily
- Consider completing current task step
- Plan for /save-state + /clear soon

### If Context is High (> 80%)
- **Immediate**: Complete current action
- **Then**: Run /save-state
- **Finally**: Run /clear
- Do not start new work until cleared

## Step 4: Context Reduction Tips

If you need to reduce context without clearing:

1. **Avoid re-reading files** already in context
2. **Use targeted reads** (specific line ranges)
3. **Reference context-registry.md** for what's essential
4. **Skip "Reference" files** unless specifically needed

## Quick Status

Run this to get a quick status summary:

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 CONTEXT STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Current task
TASK=$(grep -A1 "^## Current Task" .claude/state/active.md 2>/dev/null | tail -1 | xargs)
echo "Task: ${TASK:-none}"

# Phase
PHASE=$(grep "^PHASE:" .claude/state/active.md 2>/dev/null | cut -d':' -f2- | xargs)
echo "Phase: ${PHASE:-N/A}"

# Files in immediate context
echo ""
echo "Files to load (from active.md):"
grep -A10 "^## Immediate Context" .claude/state/active.md 2>/dev/null | grep "^- " | head -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```
