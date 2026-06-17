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
# Get current session ID (NEVER fall back to $PPID — it collides across
# terminals and corrupts state. "default" is the safe single-instance fallback.)
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_FILE=".claude/state/sessions/session-$SESSION_ID.md"

# Ensure directories exist
mkdir -p .claude/state/sessions .claude/state/locks
```

## Step 2: Reconcile Current Task (CRITICAL — prevents wrong-task corruption)

**Do this BEFORE writing to any `progress.md`.** SSM has historically saved
progress to the wrong task when the session's "Current Task" went stale. Guard
against it:

```bash
SESSION_FILE=".claude/state/sessions/session-$SESSION_ID.md"
# What the session THINKS the current task is:
STATE_TASK=$(grep -A1 "^## Current Task" "$SESSION_FILE" 2>/dev/null | tail -1 | xargs)
# What was ACTUALLY edited this session (inferred from tasks/<id>/ paths by the
# track-changes hook; most-recent entry wins):
EDITED_TASK=$(tail -1 /tmp/ssm-session-tasks-$SESSION_ID.txt 2>/dev/null | xargs)
echo "State says: '${STATE_TASK:-none}'  |  Edits suggest: '${EDITED_TASK:-none}'"
```

Decision (the user already chose **warn + ask**, never silent auto-switch):

- If `EDITED_TASK` is empty or equals `STATE_TASK` → proceed normally.
- If `EDITED_TASK` is set and **differs** from `STATE_TASK` → **STOP. Do not
  write progress yet.** Ask the user explicitly, e.g.:

  > ⚠️ Current Task is **`<STATE_TASK>`** but this session edited files under
  > **`tasks/<EDITED_TASK>/`**. Saving now would write progress to
  > `<STATE_TASK>`. Which task should I save to?
  > **1)** `<EDITED_TASK>` (switch — recommended)  **2)** `<STATE_TASK>` (keep)  **3)** cancel

  Use the user's answer as the task to save to, and update "## Current Task"
  in the session file accordingly before continuing.

## Step 3: Check for Conflicting Live Sessions (foreign-lock check)

Before writing to the task, confirm no other **live** session owns it:

```bash
TASK_ID="<resolved task from Step 2>"
LOCK=".claude/state/locks/$TASK_ID.lock"
if [ -f "$LOCK" ]; then
  LOCK_OWNER=$(head -1 "$LOCK" 2>/dev/null | xargs)
  if [ -n "$LOCK_OWNER" ] && [ "$LOCK_OWNER" != "$SESSION_ID" ]; then
    HB=".claude/state/locks/$LOCK_OWNER.heartbeat"
    if [ -f "$HB" ]; then
      LAST=$(date -d "$(cat "$HB")" +%s 2>/dev/null || echo 0)
      NOW=$(date +%s)
      AGE_MIN=$(( (NOW - LAST) / 60 ))
      echo "Task '$TASK_ID' is locked by session '$LOCK_OWNER' (heartbeat ${AGE_MIN}m ago)"
    fi
  fi
fi
```

- If a **different** session owns the lock and its heartbeat is **fresh
  (< 30 min)** → **STOP and ask** the user before overwriting (the other
  session may be actively writing the same files).
- If the lock owner is stale (≥ 30 min) or missing → safe to take over; claim
  the lock (Step 4).

## Step 4: Claim the Lock & Refresh Heartbeat

```bash
TASK_ID="<resolved task>"
printf '%s\n%s\n' "$SESSION_ID" "$(date -Iseconds)" > ".claude/state/locks/$TASK_ID.lock"
date -Iseconds > ".claude/state/locks/$SESSION_ID.heartbeat"
```

## Step 5: Gather Current State

Identify what needs to be saved:

1. **Current Focus**: What are you working on right now?
2. **Progress**: What steps have been completed?
3. **Modified Files**: Which files were changed this session?
4. **Key Decisions**: What important decisions were made?
5. **Next Steps**: What should happen next?

## Step 5b: Re-affirm the Design Contract (prevents strategy drift)

Open `tasks/<task-id>/plan.md` and review its **## Design Contract** section.
This is what gets re-injected into the next session, so it MUST stay current:

- Did this session make an architectural decision, adopt a convention, or
  discover a constraint? → add a one-liner (and a matching `DEC-xx` in
  `decisions.md` for anything significant).
- Did anything in the contract turn out wrong? → correct it now.
- Keep it tight (≤ ~25 lines). It is the durable "HOW", not a progress log.

If the contract is empty/missing (older task), write a brief one now from the
approach you've actually been following — future sessions depend on it.

## Step 6: Update Session State File (CRITICAL)

Determine session state file:
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
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

## Step 7: Update Active Tasks Registry

Update `.claude/state/active-tasks.md` to reflect the task's current state.

**First, get the actual session ID:**
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
echo "Session ID: $SESSION_ID"
```

**Then update the registry row for this task:**
- Find the row matching `$TASK_ID`
- Update the Phase column to the current phase (e.g., "Phase 2")
- Keep the Session column as the actual `$SESSION_ID` value
- Update the **LastSeen** column to the current ISO timestamp

**⚠️ CRITICAL**: When updating the Session column, use the actual
`$SESSION_ID` value. NEVER write literal words like "current", "this", or
"active" — these cause session collisions.

**Example Edit:**
```
Old: | my-task | sess-abc123 | 2026-01-14 | Phase 1 | IN_PROGRESS | 2026-01-14T10:00:00Z |
New: | my-task | sess-abc123 | 2026-01-14 | Phase 2 | IN_PROGRESS | 2026-06-16T14:30:00Z |
```
The session ID stays the same — the Phase and LastSeen change.

## Step 8: Update Task Progress (If Applicable)

If working on a specific task, update `tasks/<task-id>/progress.md`:
- Check off completed items: `[x]`
- Mark current item: `[ ] **IN PROGRESS** →`
- Add any new discovered tasks

## Step 9: Commit State (Optional but Recommended)

```bash
git add .claude/state/ tasks/
git commit -m "chore: save session state - [brief description]"
```

## Step 10: Ready for Clear

After saving state:
1. Run `/clear` to start fresh
2. Your state will auto-load in the new session (via SessionStart hook)
3. Run `/continue-task` for detailed context

---

## Quick Save Checklist

```
[ ] Current Task reconciled vs edited files (NO wrong-task save)
[ ] No conflicting live session owns the task (foreign-lock check)
[ ] Lock claimed + heartbeat refreshed
[ ] Design Contract in plan.md re-affirmed/updated (strategy stays current)
[ ] Session file updated (.claude/state/sessions/session-<id>.md)
[ ] Current focus captured
[ ] Next steps listed
[ ] Modified files recorded
[ ] Task progress updated (if applicable)
[ ] Registry updated incl. LastSeen (if applicable)
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
