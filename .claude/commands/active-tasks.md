---
name: active-tasks
description: View all active tasks across all Claude sessions, including paused and recently completed
allowed-tools: Read, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(date:*), Bash(grep:*)
---

# Active Tasks Overview

Shows ALL tasks being worked on across ALL Claude Code sessions.

## CRITICAL: Source of Truth

**The `.claude/state/active-tasks.md` registry is THE authoritative source for all tasks.**

- The registry tracks ALL tasks across ALL sessions
- Session state files only track what ONE session is working on
- When showing active tasks, you MUST read and display from the REGISTRY, not just the current session

## Step 1: Read the Central Registry (REQUIRED)

This is the AUTHORITATIVE source of all active tasks:

```bash
cat .claude/state/active-tasks.md
```

**IMPORTANT**: Parse the "Currently Active" table to get ALL active tasks, not just this session's task.
Each row represents a different task being worked on by a different session.

## Step 2: Get Current Session ID

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
echo "Current session: $SESSION_ID"
```

## Step 3: List All Session State Files

```bash
ls -la .claude/state/sessions/
```

## Step 4: Gather Details for EACH Active Task

For EACH task listed in the "Currently Active" table of the registry, gather details:

```bash
# For each session file, extract its current task and status
for f in .claude/state/sessions/session-*.md; do
  if [ -f "$f" ]; then
    SESSION_NAME=$(basename "$f" .md | sed 's/session-//')
    TASK=$(grep -A1 "## Current Task" "$f" 2>/dev/null | tail -1 | xargs)
    PHASE=$(grep "PHASE:" "$f" 2>/dev/null | cut -d':' -f2 | xargs)
    UPDATED=$(grep "Updated:" "$f" 2>/dev/null | cut -d':' -f2- | xargs)
    echo "Session: $SESSION_NAME | Task: $TASK | Phase: $PHASE | Updated: $UPDATED"
  fi
done
```

## Step 5: Calculate Progress for Each Task

For each task directory that exists:

```bash
for task_dir in tasks/*/; do
  if [ -d "$task_dir" ]; then
    TASK_ID=$(basename "$task_dir")
    if [ -f "$task_dir/progress.md" ]; then
      DONE=$(grep -c '^\- \[x\]' "$task_dir/progress.md" 2>/dev/null || echo 0)
      TOTAL=$(grep -c '^\- \[' "$task_dir/progress.md" 2>/dev/null || echo 1)
      [ "$TOTAL" -eq 0 ] && TOTAL=1
      PERCENT=$((DONE * 100 / TOTAL))
      STATUS=$(grep "^Status:" "$task_dir/progress.md" 2>/dev/null | cut -d':' -f2 | xargs)
      echo "$TASK_ID: $DONE/$TOTAL ($PERCENT%) - $STATUS"
    fi
  fi
done
```

## Step 6: Detect Stale Sessions

Sessions with no activity >24 hours:

```bash
find .claude/state/sessions/ -name "session-*.md" -mtime +1 2>/dev/null
```

---

## Presentation Format

**You MUST show ALL tasks from the registry, organized as follows:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ACTIVE TASKS OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**This Session** (<current-session-id>):
└── 🟢 <task-id> - <phase> - <progress%>
    Focus: <current focus>

**Other Active Sessions**:

┌─ <task-id> ─────────────────────────────────────────┐
│ Session: <session-id>                                │
│ Phase: <phase>                                       │
│ Progress: ████████░░ <X>% (<done>/<total> steps)    │
│ Last Active: <relative time>                         │
│ Focus: <current focus>                               │
│ Status: 🟢 ACTIVE | 🟡 PAUSED | 🔴 STALE            │
└──────────────────────────────────────────────────────┘

[Repeat for EACH task in the registry's "Currently Active" table]

**Paused Tasks** (available to claim):
• <task-id> - <phase> - Paused <time ago>

**Recently Completed** (last 14 days):
• <task-id> - ✅ <date> - <duration>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Actions:**
• `/new-task <name>` - Start a new task
• `/claim-task <id>` - Take over a paused/stale task
• `/release-task` - Pause current task for others
• `/complete-task` - Finish current task
• `/task-history` - View all completed tasks
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

## Status Indicators

| Status | Indicator | Meaning |
|--------|-----------|---------|
| ACTIVE | 🟢 | Currently being worked on |
| PAUSED | 🟡 | On hold, can be claimed |
| STALE | 🔴 | No activity >24h, may need attention |
| BLOCKED | ⚠️ | Has unresolved blockers |
| PENDING | ⏳ | Created but not started |

## Relative Time Display

- < 1 hour: "X minutes ago"
- 1-24 hours: "X hours ago"
- 1-7 days: "X days ago"
- > 7 days: "X days ago (stale)"

## If No Active Tasks

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NO ACTIVE TASKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All clear! You can:
• `/new-task <name>` - Start a new task
• `/task-history` - Review completed tasks

**Recently Completed**:
• <task-id> - ✅ <date>
```

## IMPORTANT REMINDERS

1. **Show ALL tasks from registry** - Don't just show the current session's task
2. **Registry is source of truth** - Session files may be outdated
3. **Progress from progress.md** - Calculate actual progress from task files
4. **Identify your session** - Mark which task belongs to THIS session
5. **Show other sessions** - Display tasks from OTHER sessions too

## Session Ownership Rules

**CRITICAL**: Respect session boundaries when viewing tasks.

### Your Session's Task
- Can view, edit, update progress
- Can complete or release
- Full access to task files

### Other Sessions' Tasks
- Can VIEW only (read task files)
- CANNOT edit task files
- CANNOT update progress
- CANNOT change status
- To work on it: use `/claim-task <id>` (only if PAUSED/STALE)

### Ownership Verification

```bash
# Get current session
SESSION_ID="${CLAUDE_SESSION_ID:-default}"

# Check if task belongs to you
OWNER=$(grep "<task-id>" .claude/state/active-tasks.md | awk -F'|' '{print $3}' | xargs)
if [ "$OWNER" = "$SESSION_ID" ]; then
  echo "This is YOUR task"
else
  echo "This belongs to session: $OWNER"
fi
```

### Visual Ownership Indicators

In the display:
- **🔵 YOURS** - Task belongs to current session
- **⚪ OTHER** - Task belongs to different session
- **🟡 PAUSED** - Available to claim
- **🔴 STALE** - May need intervention
