---
name: release-task
description: Pause the current task and release it so other sessions can claim it. Saves state but doesn't archive.
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(date:*)
---

# Release Task

Pauses the current task and makes it available for other sessions to claim.

Use this when:
- Switching to a different task
- Taking a break and want others to continue
- Handing off work to a different context (e.g., different machine)

## Step 1: Identify Current Task

```bash
# Get current session's task
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_FILE=".claude/state/sessions/session-$SESSION_ID.md"

if [ -f "$SESSION_FILE" ]; then
  TASK_ID=$(grep -A1 "## Current Task" "$SESSION_FILE" | tail -1 | xargs)
else
  TASK_ID=$(grep -A1 "## Current Task" .claude/state/active.md | tail -1 | xargs)
fi
```

If no current task, show message:
```
No active task to release. Use /active-tasks to see available tasks.
```

## Step 2: Gather Current State

Before releasing, capture current state:

- Current Phase and Step
- Last Action completed
- Current Focus
- Modified files this session
- Any blockers or notes

## Step 3: Save State Thoroughly

This is like `/save-state` but with explicit handoff intent:

```markdown
# Release State: <task-id>

Released: <ISO timestamp>
Released By: <session-id>
Reason: <user-provided or "Manual release">

## State at Release
PHASE: <phase>
STEP: <X of Y>
LAST_ACTION: <action>
BLOCKED: <yes/no>

## Resume Instructions

To continue this task:
1. Load these files first:
   <immediate context files>
   
2. Current focus was:
   <focus description>
   
3. Next steps:
   <next steps list>

## Notes for Next Session
<any context or warnings>

## Modified Files (May Need Review)
<list of files modified this session>
```

Save to: `tasks/<task-id>/handoffs/release-<timestamp>.md`

## Step 4: Update Task Progress

Update `tasks/<task-id>/progress.md`:
- Mark any completed items as `[x]`
- Mark current item as `[ ] (PAUSED at step N)`
- Add session log entry

## Step 5: Update Registry

Update `.claude/state/active-tasks.md`:

Move task from "Currently Active" to "Paused Tasks":

```markdown
## Paused Tasks

| Task ID | Last Session | Paused Since | Phase | Reason |
|---------|--------------|--------------|-------|--------|
| <task-id> | <session-id> | <timestamp> | <phase> | Released for handoff |
```

## Step 6: Clear Session State

Update current session:
- Set Current Task to "none"
- Clear Working Files
- Add release entry to Session Log

```markdown
| <timestamp> | Released Task | Released <task-id> for other sessions |
```

## Step 7: Confirm Release

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TASK RELEASED: <task-id>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Status**: PAUSED (available for other sessions)
**Released At**: <timestamp>
**State Saved To**: tasks/<task-id>/handoffs/release-<timestamp>.md

**Resume Instructions Saved**:
• Phase: <phase> (Step <X> of <Y>)
• Focus: <focus>
• Files to load: <count> files

**To Reclaim This Task**:
/claim-task <task-id>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**This Session** is now free. You can:
• `/new-task <n>` - Start something new
• `/claim-task <id>` - Work on a different task
• `/active-tasks` - See all tasks
```

## Optional: Release Reason

If the user provides a reason, include it:

```
/release-task Switching to urgent bugfix
```

The reason gets stored in:
- The release handoff file
- The registry's "Reason" column
- The session log

## Quick Release (No Prompt)

If user just types `/release-task` without context:

1. Save current state automatically
2. Use default reason: "Manual release"
3. Show confirmation

## With Uncommitted Changes Warning

If there are uncommitted git changes:

```
⚠️ UNCOMMITTED CHANGES DETECTED

The following files have unsaved changes:
• <file1> (modified)
• <file2> (new)

Options:
1. **Release anyway** - Changes remain in working directory
2. **Commit first** - Stage and commit before releasing
3. **Cancel** - Keep task active

Choose [1/2/3]:
```
