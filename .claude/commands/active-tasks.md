---
name: active-tasks
description: View all active tasks across all Claude sessions, including paused and recently completed
allowed-tools: Read, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(date:*)
---

# Active Tasks Overview

Shows all tasks being worked on across all Claude Code sessions.

## Step 1: Read Registry

```bash
cat .claude/state/active-tasks.md
```

## Step 2: Gather Session Details

For each active task, read the session state:

```bash
# List all session files
ls -la .claude/state/sessions/

# For each session, get current status
for f in .claude/state/sessions/session-*.md; do
  echo "=== $f ==="
  grep -A1 "## Current Task" "$f"
  grep "PHASE:" "$f"
  grep "Updated:" "$f"
done
```

## Step 3: Detect Stale Sessions

A session is considered stale if:
- Last updated more than 24 hours ago
- No activity in the session log

```bash
# Check file modification times
find .claude/state/sessions/ -name "session-*.md" -mtime +1
```

## Step 4: Present Overview

Format the output as:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ACTIVE TASKS OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**This Session** (<current-session-id>):
└── <task-id> - <phase> - <progress%>
    Focus: <current focus>

**Other Active Sessions**:

┌─ <task-id> ─────────────────────────────────────────┐
│ Session: <session-id>                                │
│ Phase: <phase>                                       │
│ Progress: ████████░░ <X>% (<done>/<total> steps)    │
│ Last Active: <relative time>                         │
│ Focus: <current focus>                               │
│ Status: ACTIVE | PAUSED | STALE                      │
└──────────────────────────────────────────────────────┘

**Paused Tasks** (available to claim):
• <task-id> - <phase> - Paused <time ago>

**Recently Completed** (last 7 days):
• <task-id> - ✅ <date> - <duration>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Actions:**
• `/new-task <n>` - Start a new task
• `/claim-task <id>` - Take over a paused/stale task
• `/release-task` - Pause current task for others
• `/complete-task` - Finish current task
• `/task-history` - View all completed tasks
```

## Step 5: Calculate Progress

For each task, calculate progress from progress.md:

```bash
# Count checked vs unchecked items
DONE=$(grep -c "^\s*\[x\]" tasks/<task-id>/progress.md 2>/dev/null || echo 0)
TOTAL=$(grep -c "^\s*\[" tasks/<task-id>/progress.md 2>/dev/null || echo 1)
PERCENT=$((DONE * 100 / TOTAL))
```

## Progress Bar Visualization

```
0-10%:   █░░░░░░░░░
10-20%:  ██░░░░░░░░
20-30%:  ███░░░░░░░
30-40%:  ████░░░░░░
40-50%:  █████░░░░░
50-60%:  ██████░░░░
60-70%:  ███████░░░
70-80%:  ████████░░
80-90%:  █████████░
90-100%: ██████████
```

## Relative Time Display

- < 1 hour: "X minutes ago"
- 1-24 hours: "X hours ago"
- 1-7 days: "X days ago"
- > 7 days: "X days ago (stale)"

## Status Indicators

| Status | Indicator | Meaning |
|--------|-----------|---------|
| ACTIVE | 🟢 | Currently being worked on |
| PAUSED | 🟡 | On hold, can be claimed |
| STALE | 🔴 | No activity >24h, may need attention |
| BLOCKED | ⚠️ | Has unresolved blockers |

## If No Active Tasks

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NO ACTIVE TASKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All clear! You can:
• `/new-task <n>` - Start a new task
• `/task-history` - Review completed tasks

**Recently Completed**:
• <task-id> - ✅ <date>
```
