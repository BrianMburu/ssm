---
name: multi-instance
description: Coordinates work across Claude sessions. Activates on "other terminal", "other session", "parallel work", "what else", "hand off", "take over", "claim task", "switch task", or "who's working on".
allowed-tools: Read, Write, Edit, Bash(ls:*), Bash(date:*), Bash(find:*)
---

# Multi-Instance Coordinator Skill

Manages task allocation across multiple concurrent Claude Code sessions.

## Critical: Session Ownership Rules

**NEVER modify tasks owned by other sessions.**

Each session can ONLY:
- Create new tasks (owned by this session)
- Modify tasks IT owns (same session ID)
- Claim PAUSED tasks (changes ownership)
- Release its own tasks (marks PAUSED)

**When creating a new task:**
1. Find tasks owned by THIS session only
2. Mark only THOSE as PAUSED
3. NEVER touch other sessions' tasks

## When to Auto-Activate

**Checking Other Work:**
- "What else is being worked on?"
- "What are other sessions doing?"
- "Is anyone working on X?"

**Switching/Handoff:**
- "Switch to another task"
- "Hand this off"
- "Take over X task" / "Claim X"

**Parallel Work:**
- "In my other terminal..."
- "I have another session..."

## Session Identification

```bash
# Get current session ID
SESSION_ID="${CLAUDE_SESSION_ID:-default}"

# This session's state file
SESSION_STATE=".claude/state/sessions/session-$SESSION_ID.md"
```

## Task Registry Structure

`.claude/state/active-tasks.md`:

```markdown
## Currently Active

| Task ID | Session | Status | Started | Phase |
|---------|---------|--------|---------|-------|
| task-1  | abc123  | IN_PROGRESS | 2026-01-14 | Phase 2 |
| task-2  | def456  | IN_PROGRESS | 2026-01-14 | Phase 1 |

## Paused / Available

| Task ID | Last Session | Status | Paused At |
|---------|--------------|--------|-----------|
| task-3  | abc123       | PAUSED | 2026-01-14 |
```

## Modifying the Registry

### Adding a New Task

```bash
# ONLY add a row, don't modify existing rows
# Add to "Currently Active" section

| new-task | $SESSION_ID | IN_PROGRESS | $(date) | Phase 1 |
```

### Pausing Your Own Task

```bash
# Find YOUR task (match session ID)
# Move from "Currently Active" to "Paused / Available"
# Change status to PAUSED
# Add paused timestamp
```

### Claiming a Paused Task

```bash
# Remove from "Paused / Available"
# Add to "Currently Active" with YOUR session ID
# Change status to IN_PROGRESS
```

## Common Workflows

### Check What's Active

```
User: "What's being worked on?"

1. Read active-tasks.md
2. Show all active tasks
3. Highlight which is THIS session's task
4. Show session IDs for context
```

### Create New Task (Session-Safe)

```
User: /new-task feature-x

1. SESSION_ID = $CLAUDE_SESSION_ID
2. Find tasks where Session = $SESSION_ID
3. Mark ONLY those as PAUSED (move to Paused section)
4. Create new task owned by $SESSION_ID
5. Add to Currently Active with $SESSION_ID
6. Other sessions' tasks UNCHANGED
```

### Hand Off to Another Session

```
Terminal 1 (session abc123):
  /release-task
  → Marks task-1 as PAUSED
  → Moves to "Paused / Available"
  → Only affects abc123's task

Terminal 2 (session def456):
  /claim-task task-1
  → Removes from "Paused / Available"
  → Adds to "Currently Active" with def456
  → task-2 (if def456 owns one) unchanged
```

### Parallel Development

```
Terminal 1 (abc123): /new-task auth-api
Terminal 2 (def456): /new-task payment-api

Registry shows:
| auth-api    | abc123 | IN_PROGRESS | ... |
| payment-api | def456 | IN_PROGRESS | ... |

Both work independently. Neither affects the other.
```

## Ownership Validation

Before ANY status change:

```bash
TASK_SESSION=$(grep "$TASK_ID" active-tasks.md | awk '{print $2}')

if [ "$TASK_SESSION" != "$SESSION_ID" ]; then
    # This task is NOT ours
    if [ "$STATUS" = "PAUSED" ]; then
        # Can claim paused tasks
        echo "Claiming paused task..."
    else
        # Cannot modify active task owned by another
        echo "ERROR: Task owned by session $TASK_SESSION"
        echo "Use /claim-task if they release it"
        exit 1
    fi
fi
```

## Quick Commands

| Action | Command |
|--------|---------|
| See all tasks | `/active-tasks` |
| Take over paused task | `/claim-task <id>` |
| Pause for handoff | `/release-task` |
| Complete task | `/complete-task` |

## Conflict Prevention

If trying to claim an ACTIVE task:

```
⚠️ Task 'auth-api' is active in session abc123.

Options:
1. Ask them to /release-task first
2. Wait for them to complete
3. Work on a different task

Cannot forcibly claim active tasks.
```

## Integration

- **session-state**: Handles state for each session
- **task-management**: Creates tasks with ownership
- **context-monitor**: Manages context per session

## Key Principle

> Each session is independent. Tasks have owners.
> Only modify what you own. Claim what's released.
