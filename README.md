# Session State Manager (SSM) for Claude Code

A structured context and task management system that prevents context loss during compaction and enables efficient multi-session workflows.

## ✨ Key Features

- **Multi-Instance Support**: Run multiple Claude Code terminals, each on different tasks
- **Session Isolation**: Each instance has its own state file - no conflicts
- **Task Registry**: Central tracking of all active, paused, and completed tasks
- **Smart Handoffs**: Seamlessly pass work between terminals
- **Context Preservation**: Save state before `/clear`, auto-reload after
- **Task Completion**: Proper archival with summaries and history

## The Problem This Solves

When Claude Code's context window fills up, it triggers **compaction** — an automatic summarization that loses critical details. SSM solves this with:

```
Traditional:
Session → work → compaction → degraded work → compaction → context soup

SSM Approach:
Session → work → /save-state → /clear → fresh session + full state loaded
```

## Quick Start

### 1. Install

```bash
./setup.sh /path/to/your/project
# Or manually:
cp -r ssm-template/.claude /path/to/project/
cp -r ssm-template/tasks /path/to/project/
cp ssm-template/CLAUDE.md /path/to/project/
```

### 2. Start Working

```bash
claude
> /new-task auth-refactor    # Creates task structure
> # ... work on the task ...
> /save-state                 # Save progress
> /clear                      # Fresh context
> /continue-task              # Reload and continue
```

### 3. Multi-Terminal Workflow

```bash
# Terminal 1                    # Terminal 2
> /new-task auth-api           > /new-task payment-api
> # work on auth...            > # work on payment...
> /active-tasks                > /active-tasks
  # Shows both tasks             # Shows both tasks
```

## Directory Structure

```
your-project/
├── CLAUDE.md                    # Project config
├── .claude/
│   ├── settings.json            # Hook registrations
│   ├── state/
│   │   ├── active.md            # Single-instance fallback
│   │   ├── active-tasks.md      # ★ Task registry (all sessions)
│   │   ├── sessions/            # ★ Per-session state files
│   │   │   ├── session-abc123.md
│   │   │   └── session-def456.md
│   │   ├── context-registry.md
│   │   └── completed/           # ★ Archived completed tasks
│   ├── hooks/
│   │   ├── session-start.sh     # Multi-instance aware
│   │   ├── pre-compact.sh
│   │   ├── track-changes.sh
│   │   └── context-check.sh
│   ├── commands/
│   │   ├── save-state.md
│   │   ├── continue-task.md
│   │   ├── new-task.md
│   │   ├── task-status.md
│   │   ├── ssm-status.md
│   │   ├── complete-task.md     # ★ NEW
│   │   ├── active-tasks.md      # ★ NEW
│   │   ├── claim-task.md        # ★ NEW
│   │   ├── release-task.md      # ★ NEW
│   │   └── task-history.md      # ★ NEW
│   ├── skills/
│   │   ├── session-state/
│   │   ├── task-management/
│   │   ├── context-monitor/
│   │   └── multi-instance/      # ★ NEW
│   ├── rules/
│   └── scripts/
└── tasks/
    ├── .templates/
    └── <task-id>/               # Per-task directories
```

## Commands Reference

### Task Lifecycle

| Command | Purpose |
|---------|---------|
| `/new-task <id>` | Create new task, register in active-tasks |
| `/task-status` | Show current task progress |
| `/complete-task` | Mark done, create summary, archive |
| `/task-history [id]` | View completed tasks |

### Session Management

| Command | Purpose |
|---------|---------|
| `/save-state` | Save to session-specific state file |
| `/continue-task` | Load session state, continue work |
| `/ssm-status` | Show SSM status summary |

### Multi-Instance Coordination

| Command | Purpose |
|---------|---------|
| `/active-tasks` | View ALL tasks across ALL sessions |
| `/claim-task <id>` | Take over task from another session |
| `/release-task` | Pause task, allow others to claim |

### Built-in Commands (Use These!)

| Command | Purpose |
|---------|---------|
| `/context` | View context usage (colored grid) |
| `/todos` | List TODO/FIXME items in code |
| `/clear` | Clear conversation, start fresh |
| `/resume` | Resume previous conversation |

## Multi-Instance Workflow

### Running Parallel Tasks

```
┌─────────────────────────────────┬─────────────────────────────────┐
│ Terminal 1 (Session: abc123)    │ Terminal 2 (Session: def456)    │
├─────────────────────────────────┼─────────────────────────────────┤
│ $ claude                        │ $ claude                        │
│ > /new-task auth-refactor       │ > /new-task payment-api         │
│                                 │                                 │
│ Working on: auth-refactor       │ Working on: payment-api         │
│ Phase: Implementation (3/7)     │ Phase: Planning                 │
│                                 │                                 │
│ > /active-tasks                 │ > /active-tasks                 │
│ Shows:                          │ Shows:                          │
│ - auth-refactor (this session)  │ - payment-api (this session)    │
│ - payment-api (session def456)  │ - auth-refactor (session abc123)│
└─────────────────────────────────┴─────────────────────────────────┘
```

### Handing Off Work

```bash
# Terminal 1: Need to stop working on auth
> /release-task
# Task marked as PAUSED, saved to handoffs/

# Terminal 2: Take over auth work
> /claim-task auth-refactor
# Loads previous state, shows where they left off
```

### Task Completion

```bash
> "All tests pass, auth-refactor is done!"

> /complete-task
# Verifies acceptance criteria
# Creates completion summary
# Archives to .claude/state/completed/
# Clears session state
# Suggests next task
```

## State Files Explained

### Per-Session State (`.claude/state/sessions/session-<id>.md`)

Each Claude instance gets its own state file:

```markdown
# Session State: abc123

Created: 2026-01-10T09:00:00Z
Updated: 2026-01-11T14:30:00Z

## Current Task
auth-refactor

## Status
PHASE: Implementation (Step 3 of 7)
BLOCKED: No
LAST_ACTION: Wrote unit tests

## Current Focus
Write integration tests

## Next Steps
1. [ ] Integration tests
2. [ ] Update API routes
```

### Task Registry (`.claude/state/active-tasks.md`)

Central tracking of all tasks:

```markdown
## Currently Active

| Task ID | Session | Started | Phase | Status |
|---------|---------|---------|-------|--------|
| auth-refactor | abc123 | 2026-01-10 | Implementation (3/7) | ACTIVE |
| payment-api | def456 | 2026-01-11 | Planning | ACTIVE |

## Paused Tasks

| Task ID | Last Session | Paused Since | Phase | Reason |
|---------|--------------|--------------|-------|--------|
| mobile-sync | xyz789 | 2026-01-09 | Implementation | Released for handoff |

## Recently Completed

| Task ID | Completed | Duration | Sessions | Outcome |
|---------|-----------|----------|----------|---------|
| user-dashboard | 2026-01-09 | 3 days | 7 | ✅ Success |
```

## Skills (Auto-Activated)

| Skill | Triggers On |
|-------|-------------|
| `session-state` | "save state", "continue", "before clearing" |
| `task-management` | "new task", "progress", "plan" |
| `context-monitor` | "context", "tokens", loading files |
| `multi-instance` | "other terminals", "parallel", "handoff" |

## Best Practices

1. **One task per session**: Keep work isolated
2. **Save often**: Don't wait for context warnings
3. **Use /active-tasks**: Know what's being worked on
4. **Complete properly**: Don't abandon tasks, use /complete-task
5. **Release when pausing**: Use /release-task for clean handoffs

## Troubleshooting

### Session state not loading
- Check `$CLAUDE_SESSION_ID` is set
- Verify session file exists in `.claude/state/sessions/`
- Falls back to `active.md` if no session file

### Task conflicts between terminals
- Only one session can own a task at a time
- Use `/release-task` before switching
- Use `/claim-task` to take over paused tasks

### Stale sessions detected
- Sessions >24h inactive show stale warning
- Can be reclaimed by other sessions
- Review state before continuing

## License

MIT - Use freely in your projects.
