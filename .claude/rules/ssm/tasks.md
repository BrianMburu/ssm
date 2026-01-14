# Task Management Rules

Rules that apply when working in the tasks/ directory.

## Task File Standards

### Timestamps
Always use ISO 8601: `2026-01-10T14:30:00Z`

### Status Values
- `NOT_STARTED` - Created but not begun
- `IN_PROGRESS` - Actively working
- `BLOCKED` - Cannot proceed (document why)
- `PAUSED` - Intentionally stopped
- `COMPLETED` - All done
- `ARCHIVED` - Moved to completed/

### Checkbox Format
- `[ ]` - Not started
- `[ ] **NEXT** →` - Immediate next
- `[x]` - Done
- `[-]` - Skipped

## Task Lifecycle

### Creating Tasks
1. Use `/new-task <id>` or just describe what you want to do
2. Minimal structure: one task.md file to start
3. Add plan.md, decisions.md only when needed

### Completing Tasks
1. Verify all acceptance criteria met
2. Run `/complete-task`
3. Task moves to `.claude/state/completed/`

### Handing Off Tasks
1. Run `/release-task` to pause
2. Other session runs `/claim-task <id>`
3. State transfers cleanly

## Progressive Disclosure

Start minimal, add structure as needed:

| Situation | Add |
|-----------|-----|
| Simple fix | Just task.md |
| Multi-step feature | + plan.md |
| Major decision | + decisions.md |
| Handoff needed | + handoffs/ |
