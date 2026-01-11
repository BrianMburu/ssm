---
name: save-state
description: Save current session state before /clear. Multi-instance aware - saves to session-specific file.
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(date:*), Bash(mkdir:*)
---

# Save Session State

Before running `/clear`, execute this workflow to preserve your progress.

## Multi-Instance Aware

This command saves to session-specific state files:
- Session file: `.claude/state/sessions/session-<id>.md`
- Also updates: `.claude/state/active-tasks.md` (registry)
- Fallback: `.claude/state/active.md` (single-instance mode)

## Step 1: Identify Session

```bash
# Get current session ID
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_FILE=".claude/state/sessions/session-$SESSION_ID.md"

# Ensure directory exists
mkdir -p .claude/state/sessions
```

## Step 2: Gather Current State

Identify what needs to be saved:

1. **Current Focus**: What are you working on right now?
2. **Progress**: What steps have been completed?
3. **Modified Files**: Which files were changed this session?
4. **Key Decisions**: What important decisions were made?
5. **Next Steps**: What should happen next?

## Step 3: Update Session State File

Create or update `.claude/state/sessions/session-<id>.md`:

```markdown
# Session State: <session-id>

Created: <original creation time>
Updated: <current ISO timestamp>
Terminal: <terminal identifier if known>

## Current Task
<task-id from tasks/ directory>

## Status
PHASE: <Current phase name>
STEP: <X> of <Y>
BLOCKED: <Yes/No>
LAST_ACTION: <Most recent completed action>

## Immediate Context (Load These)
- <path/to/file1.ts> (reason)
- <path/to/file2.ts> (reason)

## Do NOT Load
- <already processed files>

## Working Files (Modified This Session)
- <files modified this session>

## Current Focus
<One clear sentence about the immediate next action>

## Next Steps
1. [ ] <Next immediate task>
2. [ ] <Following task>
3. [ ] <Subsequent task>

## Key Decisions This Session
- <Decision: Rationale>

## Blockers / Questions
- <Any blockers>

## Session Log
| Timestamp | Action | Notes |
|-----------|--------|-------|
| <timestamp> | State saved | Pre-clear save |
```

## Step 4: Update Active Tasks Registry

Update `.claude/state/active-tasks.md` to reflect current state:

1. Find the row for current task
2. Update the Phase column
3. Update any status changes

## Step 5: Update Task Progress (If Applicable)

If working on a specific task, update `tasks/<task-id>/progress.md`:
- Check off completed items: `[x]`
- Mark current item: `[ ] **IN PROGRESS** →`
- Add any new discovered tasks

## Step 6: Commit State (Optional but Recommended)

```bash
git add .claude/state/ tasks/
git commit -m "chore: save session state - [brief description]"
```

## Step 7: Ready for Clear

After saving state:
1. Run `/clear` to start fresh
2. Your state will auto-load in the new session (via SessionStart hook)
3. Run `/continue-task` for detailed context

---

## Quick Save Checklist

```
[ ] Session file updated (.claude/state/sessions/session-<id>.md)
[ ] Current focus captured
[ ] Next steps listed
[ ] Modified files recorded
[ ] Task progress updated (if applicable)
[ ] Registry updated (if applicable)
[ ] Ready for /clear
```

## Also Updates (Automatically)

- **active-tasks.md**: Registry entry for this task
- **Task progress.md**: If a task is active
- **Session log**: Entry added

## Multi-Terminal Considerations

When running multiple terminals:
- Each terminal has its own session file
- State is isolated - no conflicts
- Registry shows all active tasks across sessions
- Other sessions can see your task status
