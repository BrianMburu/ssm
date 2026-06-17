---
name: new-task
argument-hint: <task-id> [goal description]
description: Create a new task with full structure for effective multi-session work.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(mkdir:*)
  - Bash(date:*)
  - Bash(cp:*)
---

# Create New Task

Create task: **$ARGUMENTS**

## Step 1: Parse Arguments

```
Input: "$ARGUMENTS"

Examples:
- "auth-refactor" → ID: auth-refactor, Goal: (ask user)
- "add user authentication" → ID: add-user-auth, Goal: Add user authentication
- "fix-login-bug fix the login redirect issue" → ID: fix-login-bug, Goal: Fix the login redirect issue
```

If only ID provided (no goal), ask user for goal before proceeding.

## Step 2: Handle Existing Session Task

Check if this session already has an active task:

1. Read `.claude/state/active-tasks.md`
2. Find tasks owned by this session (`${CLAUDE_SESSION_ID:-default}`)
3. If found, mark ONLY those as PAUSED (preserve other sessions' tasks)
4. Update the registry

## Step 3: Create Task Structure

```bash
TASK_ID="<extracted-task-id>"
mkdir -p "tasks/$TASK_ID"
cp tasks/.templates/task.md "tasks/$TASK_ID/task.md"
cp tasks/.templates/plan.md "tasks/$TASK_ID/plan.md"
cp tasks/.templates/progress.md "tasks/$TASK_ID/progress.md"
cp tasks/.templates/context.md "tasks/$TASK_ID/context.md"
cp tasks/.templates/decisions.md "tasks/$TASK_ID/decisions.md"
```

## Step 4: Substitute Variables

Get values:
```bash
TIMESTAMP=$(date -Iseconds)
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
DATE=$(date +%Y-%m-%d)
```

Use Edit tool to replace placeholders in each copied file:
- `{{TASK_ID}}` → actual task ID
- `{{TIMESTAMP}}` → ISO timestamp
- `{{SESSION_ID}}` → session ID (verbatim value)
- `{{DATE}}` → date
- `{{GOAL}}` → user's goal
- `{{GOAL_DESCRIPTION}}` → expanded goal (can match `{{GOAL}}` initially)

## Step 4b: Seed the Design Contract (critical for multi-session work)

Fill in the **## Design Contract** section of `tasks/<task-id>/plan.md` from the
approach already discussed (or from the Plan/ssm-planner agent's output if one
ran). At minimum capture the intended Approach and any known Invariants and
Anti-goals. This is the binding "HOW" re-injected on every resume — a few solid
lines now prevent the implementation from drifting across sessions later. Keep
it tight (≤ ~25 lines). If the approach is still genuinely unknown, note that
explicitly and fill it in at the end of Phase 1 (Research).

## Step 5: Register Task

**Get session ID** (must be numeric):
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
```

Add to `.claude/state/active-tasks.md` under "Currently Active":
```markdown
| <task-id> | <SESSION_ID> | IN_PROGRESS | <DATE> | <goal summary> |
```

**CRITICAL**: Use the actual NUMERIC session ID, never literal words like "current".

## Step 6: Update Session State

```bash
SESSION_STATE=".claude/state/sessions/session-${CLAUDE_SESSION_ID:-default}.md"
```

Update `$SESSION_STATE`:
- Set Current Task to `<task-id>`
- Set LAST_ACTION to "Created task <task-id>"
- Set Current Focus to "Begin Phase 1: Research"
- Add task files to Immediate Context
- Add entry to Session History

## Step 7: Confirm and Begin

Output:
```
✅ Task created: <task-id>

Goal: <GOAL>

Structure:
  tasks/<task-id>/
  ├── task.md      ← Metadata and status
  ├── plan.md      ← Design Contract + implementation phases
  ├── progress.md  ← Progress tracking (source of truth)
  ├── context.md   ← Files to load
  └── decisions.md ← Key decisions

Current phase: Phase 1 - Research
First step: Explore relevant code

Ready to begin. What area of the codebase should we explore first?
```

Then begin working on Phase 1.

## Notes

- Templates are in `tasks/.templates/`
- progress.md is the source of truth for progress
- TodoWrite sync handled by task-management skill (auto-activates)
- Session ownership prevents task collisions in multi-instance mode
