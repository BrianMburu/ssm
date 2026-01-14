---
name: start
argument-hint: <what to work on>
description: Start working on something immediately. Quickest way to begin a task.
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(date:*), TodoWrite
---

# Quick Start: $ARGUMENTS

Start working on: **$ARGUMENTS**

## Instant Setup (< 15 seconds)

### 1. Parse Intent

From "$ARGUMENTS", determine:
- **Task ID**: kebab-case identifier (e.g., "add-dark-mode")
- **Goal**: What the user wants to accomplish

If unclear, the description IS the goal. Generate a short task ID from it.

### 2. Create Minimal Structure

```bash
TASK_ID="<generated-id>"
mkdir -p "tasks/$TASK_ID"
```

Create `tasks/$TASK_ID/task.md`:

```markdown
# Task: $TASK_ID

Created: <now>
Status: IN_PROGRESS

## Goal

$ARGUMENTS

## Notes

<!-- Will be added as work progresses -->
```

### 3. Quick State Update

Update `.claude/state/active.md`:
- Current Task: $TASK_ID
- Current Focus: $ARGUMENTS
- PHASE: Implementation
- LAST_ACTION: Task started

### 4. Register (One Line)

Add to `.claude/state/active-tasks.md`:
```
| $TASK_ID | <session> | <today> | Active | IN_PROGRESS |
```

### 5. Initialize Todos

```javascript
TodoWrite([
  { content: "Understand the codebase area", status: "in_progress", activeForm: "Understanding codebase" },
  { content: "Implement the changes", status: "pending", activeForm: "Implementing" },
  { content: "Verify it works", status: "pending", activeForm: "Verifying" }
])
```

### 6. START WORKING

Output:
```
Started: $TASK_ID
Goal: $ARGUMENTS

Let me explore the relevant code...
```

Then IMMEDIATELY begin exploring the codebase to understand what needs to change.
Do NOT ask clarifying questions unless absolutely necessary.
Do NOT create additional planning files.
Just start working.
