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

## Step 2: Check Task Status & Liveness

Read the registry to determine task status, then use the owning session's
**heartbeat** to decide whether it is genuinely live (not just "IN_PROGRESS"
in a stale registry row):

| Status | Can Claim? | Action |
|--------|------------|--------|
| PAUSED | ✅ Yes | Direct claim |
| IN_PROGRESS, owner heartbeat ≥ 30m (STALE) | ✅ Yes | Claim with warning |
| IN_PROGRESS, owner heartbeat < 30m (LIVE) | ⚠️ Confirm | May disrupt an active session |
| Owned by current session | ❌ No | Already yours |

```bash
# Get current owner from the registry
OWNER=$(grep "$ARGUMENTS" .claude/state/active-tasks.md | awk -F'|' '{print $3}' | xargs)

# Determine liveness from the owner's heartbeat (authoritative source)
HB=".claude/state/locks/$OWNER.heartbeat"
LIVE="no"
if [ -f "$HB" ]; then
  LAST=$(date -d "$(cat "$HB")" +%s 2>/dev/null || echo 0)
  AGE_MIN=$(( ( $(date +%s) - LAST ) / 60 ))
  [ "$AGE_MIN" -lt 30 ] && LIVE="yes"
  echo "Owner '$OWNER' heartbeat ${AGE_MIN}m ago (live: $LIVE)"
else
  echo "No heartbeat for owner '$OWNER' — treat as stale/safe to claim"
fi
```

If `LIVE=yes`, this is genuinely an active session — go to Step 3 (confirm).
If `LIVE=no`, the previous session is stale/crashed — claim is safe.

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

Update `.claude/state/active-tasks.md` to transfer ownership.

**First, get the actual session ID and take the lock:**
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
mkdir -p .claude/state/locks
# Take ownership of the task lock and start our own heartbeat
printf '%s\n%s\n' "$SESSION_ID" "$(date -Iseconds)" > ".claude/state/locks/$ARGUMENTS.lock"
date -Iseconds > ".claude/state/locks/$SESSION_ID.heartbeat"
echo "Session ID: $SESSION_ID (lock taken on $ARGUMENTS)"
```

**Then update the registry row for the claimed task:**
1. Find the row for `$ARGUMENTS` (the task being claimed)
2. Change Session column to the actual `$SESSION_ID` value
3. Update Status to "IN_PROGRESS"
4. Update the LastSeen column to the current ISO timestamp

**⚠️ CRITICAL**: When updating the Session column, write the actual
`$SESSION_ID` value, NOT literal words like "current", "new", or "this
session". Literal strings cause multi-session collisions.

**Example Edit:**
```
Old: | my-task | sess-old111 | 2026-01-14 | Phase 2 | PAUSED      | 2026-01-14T09:00:00Z |
New: | my-task | sess-new222 | 2026-01-14 | Phase 2 | IN_PROGRESS | 2026-06-16T14:30:00Z |
```
Note: `sess-new222` is the NEW session's ID, replacing the old session's ID.

## Step 7: Update Session States (CRITICAL)

Determine session state files:
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
CURRENT_SESSION_STATE=".claude/state/sessions/session-$SESSION_ID.md"
```

**Previous session** (if exists):
- Set Current Task to "None"
- Set LAST_ACTION to "Task claimed by session-<new-session>"
- Add log entry: "Task claimed by <new-session>"

**Current session** (update `$CURRENT_SESSION_STATE`):
- Set Current Task to claimed task ID
- Set LAST_ACTION to "Claimed task <task-id> from <prev-session>"
- Copy Phase, Step, Focus from previous session
- Load Immediate Context files
- Add entry to Session History table:
  ```markdown
  | <timestamp> | Task claimed | Claimed <task-id> from <prev-session> |
  ```

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
