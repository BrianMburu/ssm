# State File Rules

Rules that apply when working with .claude/state/ files.

## State File Hierarchy

```
.claude/state/
├── active.md           # Single-instance fallback
├── active-tasks.md     # Task registry (all sessions) — has a LastSeen column
├── context-registry.md # File token estimates
├── sessions/           # Per-session state
│   └── session-<id>.md
├── locks/              # Runtime only (git-ignored)
│   ├── <session-id>.heartbeat  # last-active ISO ts; LIVE if < 30 min
│   └── <task-id>.lock          # owning session id
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
- Ownership tracked in active-tasks.md + a lock in `locks/<task>.lock`
- Liveness tracked via `locks/<session>.heartbeat` (LIVE if < 30 min old)
- Use `/release-task` before switching sessions
- Use `/claim-task` to take over paused or stale work

## Wrong-Task Guard (v3)

Before `/save-state` writes to any `progress.md`, it reconciles the session's
"Current Task" against the task actually edited this session (inferred from
`tasks/<id>/` paths by the track-changes hook). On mismatch it **stops and
asks** rather than silently writing to the wrong task. Never bypass this guard.
