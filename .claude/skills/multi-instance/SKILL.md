---
name: multi-instance-coordinator
description: Coordinates work across multiple Claude Code sessions. Use when user mentions other terminals, parallel work, switching tasks, handoffs, or asks what else is being worked on.
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(ls:*), Bash(date:*), Bash(find:*), Bash(grep:*)
---

# Multi-Instance Coordinator Skill

Manages task allocation and state across multiple concurrent Claude Code sessions.

## When to Activate

Automatically activate when user:
- Mentions "other sessions", "other terminals", "other instances"
- Asks "what else is being worked on" or "parallel work"
- Wants to "switch tasks" or "hand off"
- Mentions "different task" or "work on something else"
- Asks about task ownership or claiming

## Key Files

| File | Purpose |
|------|---------|
| `.claude/state/active-tasks.md` | Registry of all tasks and their owners |
| `.claude/state/sessions/session-<id>.md` | Per-session state files |
| `$CLAUDE_SESSION_ID` | Current session identifier (env var) |

## Session Identification

Each Claude Code instance has a unique session ID:
- Available via `$CLAUDE_SESSION_ID` environment variable
- If not set, generate from: `default-$(date +%s)-$$`
- Used to isolate state between instances

## Task Ownership Rules

1. **Exclusive Ownership**: Each task has ONE active session at a time
2. **ACTIVE**: Session is currently working on the task
3. **PAUSED**: Task on hold, available for claim
4. **STALE**: No activity >24 hours, can be reclaimed
5. **QUICK_FIX**: Temporary access without changing ownership

## Detecting Other Sessions

```bash
# List all active sessions
ls -la .claude/state/sessions/session-*.md

# Find sessions working on specific task
grep -l "task-id" .claude/state/sessions/*.md

# Check session activity (file modification time)
find .claude/state/sessions -name "*.md" -mtime -1  # Active in last 24h
find .claude/state/sessions -name "*.md" -mtime +1  # Stale (>24h)
```

## Coordination Workflows

### Switching Tasks

When user wants to switch to a different task:

1. Save current task state (`/save-state`)
2. Mark current task as PAUSED in registry
3. Claim or create new task
4. Load new task state

### Parallel Work

When user has multiple terminals:

1. Each terminal gets its own session file
2. Each works on different task (enforced by registry)
3. Show other sessions' status via `/active-tasks`
4. Handoffs via `/release-task` and `/claim-task`

### Handoff Between Sessions

When passing work to another session/terminal:

1. Source session: `/release-task` (saves state, marks PAUSED)
2. Creates handoff file with resume instructions
3. Target session: `/claim-task <id>` (loads state, marks ACTIVE)
4. Updates registry ownership

## Conflict Prevention

### Same Task, Multiple Sessions

If user tries to claim an ACTIVE task:

```
⚠️ Task is currently active in another session

Options:
1. Claim anyway (may conflict)
2. Quick fix mode (temporary, no ownership change)
3. Wait for release
4. Cancel
```

### State File Conflicts

Session files are isolated by session ID, preventing direct conflicts.
Only `active-tasks.md` is shared, and updates are additive.

## Stale Session Handling

Sessions inactive for >24 hours are considered stale:

```bash
# Find stale sessions
find .claude/state/sessions -name "*.md" -mtime +1

# Check last update in file
grep "^Updated:" .claude/state/sessions/session-*.md
```

When encountering a stale session:
1. Offer to claim the task
2. Show what was being worked on
3. Create handoff note on claim

## Quick Reference

| Action | Command |
|--------|---------|
| See all tasks | `/active-tasks` |
| Take over task | `/claim-task <id>` |
| Pause for handoff | `/release-task` |
| Complete task | `/complete-task` |
| New task | `/new-task <n>` |

## Integration with Other Skills

- **session-state**: Handles per-session state saving/loading
- **task-management**: Handles task creation and progress tracking
- **context-monitor**: Helps manage context when switching tasks

## Error Handling

| Situation | Response |
|-----------|----------|
| No other sessions | "You're the only active session" |
| Task not found | Suggest `/active-tasks` |
| Already owned by self | "You already own this task" |
| Network of sessions | Show all with status indicators |

## Example Interactions

**User**: "What else is being worked on?"
→ Read `active-tasks.md`, list all tasks with owners and status

**User**: "I need to switch to the payment task"
→ Save current state, offer to claim payment task, show handoff

**User**: "Can someone else take over this task?"
→ Run `/release-task`, mark as PAUSED, show instructions for claiming

**User**: "Is anyone working on the auth task?"
→ Check registry for auth task, show owner session and status
