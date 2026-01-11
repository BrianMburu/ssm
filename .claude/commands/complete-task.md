---
name: complete-task
description: Complete the current task, create summary, and archive. Use when all acceptance criteria are met.
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(mkdir:*), Bash(mv:*), Bash(cp:*), Bash(date:*)
---

# Complete Task

Marks the current task as complete, creates a summary, and archives the task files.

## Prerequisites

Before completing a task, verify:
1. All acceptance criteria from `plan.md` are met
2. All checklist items in `progress.md` are checked
3. No unresolved blockers

## Step 1: Identify Current Task

```bash
# Get current task from session state
cat .claude/state/sessions/session-*.md 2>/dev/null | grep -A1 "## Current Task" | tail -1
# Or from active.md if single-instance
cat .claude/state/active.md | grep -A1 "## Current Task" | tail -1
```

## Step 2: Verify Acceptance Criteria

Read the task's plan.md and check each acceptance criterion:

```bash
cat tasks/<task-id>/plan.md
```

Present each criterion to the user for confirmation:
- ✅ Criterion met
- ❌ Criterion not met (cannot complete)

**If any criterion is not met**, stop and explain what's remaining.

## Step 3: Create Completion Summary

Create a summary file with:

```markdown
# Task Completion Summary: <task-id>

## Overview
- **Task**: <task-id>
- **Goal**: <from plan.md>
- **Started**: <date>
- **Completed**: <today>
- **Duration**: <calculated>
- **Sessions Used**: <count>

## Acceptance Criteria Results
- ✅ <criterion 1>
- ✅ <criterion 2>
...

## Files Created/Modified
- <filepath> (created/modified - purpose)
...

## Key Decisions Made
<from decisions.md>

## Lessons Learned
<any notes for future similar work>

## Final Statistics
- Steps Completed: X/X (100%)
- Blockers Encountered: N
- Context Clears: N
```

## Step 4: Archive Task

```bash
# Create archive directory with date
ARCHIVE_DIR=".claude/state/completed/<task-id>-$(date +%Y-%m-%d)"
mkdir -p "$ARCHIVE_DIR"

# Copy task files to archive
cp -r tasks/<task-id>/* "$ARCHIVE_DIR/"

# Copy session states that worked on this task
cp .claude/state/sessions/session-*.md "$ARCHIVE_DIR/sessions/" 2>/dev/null || true

# Add the completion summary
# (already created in archive dir)
```

## Step 5: Update Registry

Update `.claude/state/active-tasks.md`:

1. Remove task from "Currently Active" table
2. Add to "Recently Completed" table with:
   - Task ID
   - Completion date
   - Duration
   - Number of sessions
   - Outcome (✅ Success)

## Step 6: Clear Session State

Update current session state:
- Set Current Task to "none"
- Clear Working Files
- Clear Current Focus
- Add completion entry to Session Log

## Step 7: Offer Next Steps

After completion, offer:

1. **Start new task**: `/new-task <name>`
2. **Claim existing task**: Show paused tasks from registry
3. **View task history**: `/task-history`
4. **End session**: Clean exit

## Completion Checklist

```
[ ] All acceptance criteria verified
[ ] Completion summary created
[ ] Task files archived
[ ] Registry updated
[ ] Session state cleared
[ ] User informed of next options
```

## If User Declines Completion

If some criteria aren't met, offer:
1. Continue working on remaining items
2. Mark task as PAUSED with notes
3. Create sub-task for remaining work
