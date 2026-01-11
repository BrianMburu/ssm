---
name: claim-task
argument-hint: <task-id>
description: Take over a paused or stale task from another session. Use when you want to continue work started elsewhere.
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(date:*), Bash(cp:*)
---

# Claim Task

Takes ownership of a task from another session, allowing you to continue the work.

## Usage

```
/claim-task <task-id>
```

## Step 1: Validate Task Exists

```bash
# Check task directory exists
ls -la tasks/$ARGUMENTS/

# Check task is in registry
grep "$ARGUMENTS" .claude/state/active-tasks.md
```

If task doesn't exist, show error and suggest `/active-tasks` to see available tasks.

## Step 2: Check Task Status

Read the registry to determine task status:

| Status | Can Claim? | Action |
|--------|------------|--------|
| PAUSED | ✅ Yes | Direct claim |
| STALE (>24h inactive) | ✅ Yes | Claim with warning |
| ACTIVE | ⚠️ Confirm | Requires confirmation (may disrupt other session) |
| Owned by current session | ❌ No | Already yours |

```bash
# Get current owner
OWNER=$(grep "$ARGUMENTS" .claude/state/active-tasks.md | awk -F'|' '{print $3}' | xargs)
```

## Step 3: Handle Active Task Warning

If task is currently ACTIVE in another session:

```
⚠️ WARNING: Task is actively being worked on

Task: <task-id>
Session: <session-id>
Last Active: <time ago>
Current Focus: <focus>

Claiming this task may cause conflicts if the other session is still running.

Options:
1. **Claim anyway** - Take over (other session will see a warning)
2. **Quick fix mode** - Temporary access without claiming
3. **Cancel** - Don't claim

Choose [1/2/3]:
```

## Step 4: Load Previous Session State

Find and read the session that was working on this task:

```bash
# Find session file for this task
PREV_SESSION=$(grep -l "## Current Task" .claude/state/sessions/*.md | xargs grep -l "$ARGUMENTS" | head -1)

if [ -n "$PREV_SESSION" ]; then
  cat "$PREV_SESSION"
fi
```

## Step 5: Create Handoff Summary

Before claiming, create a handoff note:

```markdown
## Handoff: <task-id>

From: <previous-session-id>
To: <current-session-id>
Timestamp: <ISO 8601>

### State at Handoff
- Phase: <phase>
- Step: <X of Y>
- Last Action: <last action>
- Current Focus: <focus>

### Files to Load
<from previous session's Immediate Context>

### Pending Work
<from previous session's Next Steps>

### Notes
<any blockers or context>
```

Save to: `tasks/<task-id>/handoffs/handoff-<timestamp>.md`

## Step 6: Update Registry

Update `.claude/state/active-tasks.md`:

1. Change the Session column to current session ID
2. Update the Status to ACTIVE
3. Add handoff note to task's history

## Step 7: Update Session States

**Previous session** (if exists):
- Set Current Task to "none"
- Add log entry: "Task claimed by <new-session>"

**Current session**:
- Set Current Task to claimed task ID
- Copy Phase, Step, Focus from previous session
- Load Immediate Context files
- Add log entry: "Claimed task from <prev-session>"

## Step 8: Present Context

Show the claimed task's current state:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TASK CLAIMED: <task-id>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Previous Owner**: <session-id> (last active <time ago>)
**Phase**: <phase> (Step <X> of <Y>)
**Progress**: ████████░░ <X>%

**Where they left off**:
<last action>

**Current Focus**:
<focus from previous session>

**Next Steps**:
1. [ ] <next step>
2. [ ] <following step>

**Files Loaded**:
• <file1>
• <file2>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready to continue! What would you like to work on?
```

## Quick Fix Mode

If user chooses quick fix mode instead of full claim:

1. Don't update task ownership in registry
2. Create a temporary session note
3. Work on the fix
4. When done, changes are attributed but task stays with original owner

```bash
# Mark as quick fix in session state
echo "QUICK_FIX: $ARGUMENTS" >> .claude/state/sessions/session-$SESSION_ID.md
```

## Error Handling

| Error | Message |
|-------|---------|
| Task not found | "Task '<id>' not found. Run /active-tasks to see available tasks." |
| Already owned | "You already own this task in the current session." |
| No sessions for task | "No previous session state found. Starting fresh." |
