# SSM Core Rules

Essential rules that apply to all SSM-managed sessions.

## The Critical Rule

**Never let auto-compact run.** Save state and `/clear` at 70-75%.

## Context Limits (IMPORTANT)

| Level | % | Action |
|-------|---|--------|
| Safe | < 60% | Normal work |
| Warning | 60-70% | Plan to save |
| **Strong** | 70-75% | **Finish step, save+clear** |
| CRITICAL | > 75% | **SAVE NOW** |
| Danger | > 77.5% | Auto-compact buffer zone |

**Why 75% not 90%?** Auto-compact buffer is 45k tokens (~22.5%). Danger starts at 77.5%.

## Large Tasks Span Sessions

This is **NORMAL**:
```
Session 1: Phases 1-2 → save → clear
Session 2: Phases 3-4 → save → clear
Session 3: Phases 5-6 → complete
```

Progress preserved in `progress.md`. No context loss.

## State Management

1. **progress.md is source of truth** - Not TodoWrite
2. **plan.md guides work** - Check phases and checkpoints
3. **context.md lists files** - Load only what's needed
4. **active.md tracks session** - Current focus and next steps

## Session Workflow

```
Start:  Load active.md → Load context.md files → Check plan.md phase
Work:   Update progress.md after each step → Watch context %
Save:   /save-state → Update all files → /clear
Resume: State auto-loads → Continue from progress.md
```

## Commands Quick Reference

| Action | Command |
|--------|---------|
| New task | `/new-task <id>` |
| Check status | `/task-status` |
| Save progress | `/save-state` |
| Resume work | `/continue-task` |
| View all tasks | `/active-tasks` |
| Fresh start | `/save-state` then `/clear` |

## Task Structure (Required)

```
tasks/<task-id>/
├── task.md      # Goal, status, metadata
├── plan.md      # Implementation phases + checkpoints
├── progress.md  # Detailed progress (source of truth)
├── context.md   # Files to load, token estimates
└── decisions.md # Key decisions (when needed)
```

All files created by default. This structure enables effective multi-session work.
