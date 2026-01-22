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
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
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

## Step 3: Update Session State File (CRITICAL)

Determine session state file:
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
SESSION_STATE=".claude/state/sessions/session-$SESSION_ID.md"
```

Create or update `$SESSION_STATE`:

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
LAST_ACTION: State saved for <task-id>

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

Update `.claude/state/active-tasks.md` to reflect the task's current state.

**First, get the actual session ID:**
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
echo "Session ID: $SESSION_ID"  # Should show a number like 734239
```

**Then update the registry row for this task:**
- Find the row matching `$TASK_ID`
- Update Phase column to current phase (e.g., "Phase 2")
- Keep Session column as the NUMERIC `$SESSION_ID` value (e.g., "734239")

**⚠️ CRITICAL**: When updating the Session column, use the actual NUMERIC
session ID (e.g., "734239", "828334"). NEVER write literal words like
"current", "this", or "active" - these cause session collisions.

**Example Edit:**
```
Old: | my-task | 734239 | 2026-01-14 | Phase 1 | IN_PROGRESS |
New: | my-task | 734239 | 2026-01-14 | Phase 2 | IN_PROGRESS |
```
The session ID stays as the numeric value - only the phase changes.

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
