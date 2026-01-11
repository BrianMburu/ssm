---
name: task-management
description: Manages task creation, tracking, and progress. Use when user wants to start a new task, create a plan, track progress, or check task status.
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(cat:*), Bash(date:*)
---

# Task Management Skill

This skill helps create, track, and manage implementation tasks.

## When to Activate

Automatically activate when user:
- Wants to "start a new task" or "new feature"
- Asks about "task status" or "progress"
- Mentions "plan", "implementation steps", or "checklist"
- Wants to "track" work or see "what's left"

## Task Structure

Each task lives in `tasks/<task-id>/` with:

```
tasks/<task-id>/
├── plan.md       # Implementation steps
├── progress.md   # Checklist with status  
├── context.md    # Required files
└── decisions.md  # Key decisions made
```

## Creating a New Task

1. Create the task directory:
```bash
mkdir -p tasks/<task-id>
```

2. Create plan.md with:
   - Goal statement
   - Prerequisites
   - Numbered implementation steps by phase
   - Acceptance criteria

3. Create progress.md with:
   - Status tracking
   - Checkbox items matching plan steps
   - Session log table

4. Update `.claude/state/active.md`:
   - Set Current Task to new task ID
   - Set PHASE to "Planning"
   - Update Immediate Context with task files

## Progress Tracking

Use checkbox format:
- `[ ]` - Not started
- `[ ] **NEXT** →` - Immediate next item
- `[ ] **IN PROGRESS** →` - Currently working
- `[x]` - Completed
- `[-]` - Skipped

## Viewing Task Status

To check status:

1. Read current task from `.claude/state/active.md`
2. Read `tasks/<task-id>/progress.md`
3. Calculate completion percentage
4. Show current focus and next steps

## Integration with Built-in `/todos`

Claude Code's `/todos` command can find TODO/FIXME comments. Our task system complements this with structured planning and progress tracking.

Recommendation: Use `/todos` for code-level items, use our task system for feature-level work.

## Task Templates

For common work types, templates are in `tasks/.templates/`:
- `task-template.md` - Full template reference

Copy and customize for each new task.
