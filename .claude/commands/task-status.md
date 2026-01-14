---
name: task-status
description: Show current task progress from progress.md (source of truth)
allowed-tools: Read, Bash(cat:*), Bash(ls:*), Bash(grep:*), TodoWrite
---

# Task Status

Display comprehensive status of the current task.

**IMPORTANT**: This command reads from `progress.md` as the source of truth, NOT from TodoWrite.
The TodoWrite UI may lag behind actual progress.

## Step 1: Determine Session and State File

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_STATE=".claude/state/sessions/session-$SESSION_ID.md"
ACTIVE_STATE=".claude/state/active.md"

if [ -f "$SESSION_STATE" ]; then
    STATE_FILE="$SESSION_STATE"
else
    STATE_FILE="$ACTIVE_STATE"
fi
```

## Step 2: Get Current Task

```bash
TASK_ID=$(grep -A1 "^## Current Task" "$STATE_FILE" | tail -1 | xargs)

if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "none" ] || [ "$TASK_ID" = "None" ]; then
    echo "No active task for this session."
    echo "Use /new-task <name> to start one."
    exit 0
fi
```

## Step 3: Read Progress from progress.md (Source of Truth)

```bash
PROGRESS_FILE="tasks/$TASK_ID/progress.md"

if [ ! -f "$PROGRESS_FILE" ]; then
    echo "Warning: progress.md not found for task $TASK_ID"
    exit 1
fi

# Parse progress
TOTAL=$(grep -c '^\- \[' "$PROGRESS_FILE" 2>/dev/null || echo 0)
DONE=$(grep -c '^\- \[x\]' "$PROGRESS_FILE" 2>/dev/null || echo 0)
PERCENT=$((DONE * 100 / TOTAL))

# Get current phase
CURRENT_PHASE=$(grep "Current Phase" "$PROGRESS_FILE" | head -1 | cut -d':' -f2 | xargs)

# Get next item
NEXT_ITEM=$(grep -A1 "NEXT" "$PROGRESS_FILE" | head -1)
```

## Step 4: Read Additional Context

```bash
# Get goal from task.md
GOAL=$(grep -A1 "^## Goal" "tasks/$TASK_ID/task.md" | tail -1)

# Get current focus from state
FOCUS=$(grep -A1 "^## Current Focus" "$STATE_FILE" | tail -1)

# Check for blockers
BLOCKED=$(grep "^BLOCKED:" "$STATE_FILE" | cut -d':' -f2 | xargs)
```

## Step 5: Sync to TodoWrite (Update UI)

After reading progress.md, sync to TodoWrite so UI reflects actual state:

```
Read progress.md checkboxes and convert to TodoWrite format:
- [ ] item → status: "pending"
- [x] item → status: "completed"
- Item with **NEXT** → status: "in_progress"
```

Call TodoWrite with the parsed items to sync UI.

## Step 6: Display Status Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TASK STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: <task-id>
Goal: <goal>
Session: <session-id>

Phase: <current-phase>
Progress: ████████░░░░░░░░ <percent>% (<done>/<total> steps)

Current Focus:
→ <focus>

Next Step:
→ <next-item>

Files: tasks/<task-id>/
  ├── plan.md      - Implementation phases
  ├── progress.md  - Progress (SOURCE OF TRUTH)
  ├── context.md   - Files to load
  └── decisions.md - Key decisions

Blockers: <None | list>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Quick Actions:
  • Continue with current focus
  • /save-state → Save before clearing
  • /active-tasks → See all tasks
```

## Step 7: Show Detailed Progress

After the summary, show the detailed progress from progress.md:

```bash
echo ""
echo "=== Detailed Progress (from progress.md) ==="
echo ""
cat "$PROGRESS_FILE"
```

## Key Principles

1. **progress.md is truth** - Always read from file, not memory
2. **Sync to TodoWrite** - Update UI after reading file
3. **Show file locations** - Help user know where data lives
4. **Session-aware** - Use correct state file for session

## Progress Tracking Note

The TodoWrite UI at the bottom of Claude Code may show slightly different
progress due to async updates. The `progress.md` file is always accurate.

If UI seems out of sync:
1. Run `/task-status` to force sync
2. UI will update from progress.md
