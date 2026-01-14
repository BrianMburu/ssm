# State File Rules

Rules that apply when working with .claude/state/ files.

## State File Hierarchy

```
.claude/state/
├── active.md           # Single-instance fallback
├── active-tasks.md     # Task registry (all sessions)
├── context-registry.md # File token estimates
├── sessions/           # Per-session state
│   └── session-<id>.md
└── completed/          # Archived tasks
```

## active.md Structure

Required sections:
- **Current Task** - Task ID or "none"
- **Status** - PHASE, STEP, BLOCKED, LAST_ACTION
- **Immediate Context** - Files to load
- **Current Focus** - What to do next
- **Next Steps** - Upcoming work

## Session Files

Each Claude instance gets `session-<id>.md` containing:
- Same structure as active.md
- Isolated from other sessions
- Auto-created by session-start hook

## Updating State

### Always Update
- Current Focus (after each significant action)
- Next Steps (when completing a step)
- Working Files (auto-tracked by hook)

### Update on Save
- Session History
- Key Decisions
- Blockers/Questions

## Multi-Instance Coordination

- Only one session owns a task at a time
- Ownership tracked in active-tasks.md
- Use `/release-task` before switching sessions
- Use `/claim-task` to take over paused work
