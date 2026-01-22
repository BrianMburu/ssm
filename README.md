# Session State Manager (SSM) for Claude Code

A structured context and task management system that prevents context loss during compaction and enables efficient multi-session workflows.

## Key Features

- **Bulletproof Compaction Prevention**: Auto-compaction is completely blocked - you control when to clear
- **Auto-Save on Edits**: Working files automatically tracked after every edit
- **Context Warnings**: Proactive alerts at 50%, 60%, 70%, 75% thresholds (auto-save at 75%)
- **Full Task Structure**: Rich task files with progress.md as source of truth
- **Session State Sync**: Every action updates session state (LAST_ACTION) for accurate status display
- **Multi-Instance Support**: Run multiple Claude Code terminals with session ownership rules
- **Session Isolation**: Each instance has its own state file - no conflicts
- **Task Registry**: Central tracking of all active, paused, and completed tasks
- **Smart Handoffs**: Seamlessly pass work between terminals
- **Context Preservation**: Save state before `/clear`, auto-reload after
- **Subagent Integration**: Use Explorer and Planner agents to keep context clean
- **Multi-Session Tasks**: Large tasks spanning multiple sessions is normal and expected

## The Problem This Solves

When Claude Code's context window fills up, it triggers **compaction** — an automatic summarization that loses critical details. SSM solves this with:

```
Traditional:
Session → work → compaction → degraded work → compaction → context soup

SSM Approach:
Session → work → /save-state → /clear → fresh session + full state loaded
```

### Critical: Context Thresholds

**The auto-compact buffer is ~45k tokens (22.5%). Danger zone starts at 77.5%.**

| Level | % | Action |
|-------|---|--------|
| Safe | < 50% | Normal work |
| Notice | 50-60% | Good checkpoint opportunity |
| Warning | 60-70% | Plan to save soon |
| **Strong** | 70-75% | Finish step, then save+clear |
| **CRITICAL** | > 75% | **SAVE NOW** - 5k to danger |

**Large tasks spanning multiple sessions is NORMAL:**
```
Session 1: Phases 1-2 → save → clear
Session 2: Phases 3-4 → save → clear
Session 3: Phases 5-6 → complete
```
Progress preserved in `progress.md`. No information loss.

## Installation

### Option 1: Plugin Install (Recommended)

```bash
# In Claude Code
/plugin install ssm
```

That's it! SSM auto-initializes on first session.

### Option 2: Manual Setup

```bash
# Clone and run setup script
git clone https://github.com/brian/ssm
./ssm/setup.sh /path/to/your/project
```

### Option 3: Copy Files

```bash
cp -r ssm/.claude /path/to/project/
cp -r ssm/tasks /path/to/project/
cp ssm/CLAUDE.md /path/to/project/
```

## Quick Start

### Start Working

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
    ├── .templates/              # Task file templates
    │   ├── task.md              # Goal, status, metadata
    │   ├── plan.md              # Phases with checkpoints
    │   ├── progress.md          # ★ Source of truth
    │   ├── context.md           # Files with token estimates
    │   └── decisions.md         # Key decisions
    └── <task-id>/               # Per-task directories (full structure)
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

### Session Ownership Rules

**CRITICAL: Sessions own their tasks. Never modify another session's task.**

| Your Task | Other Session's Task |
|-----------|---------------------|
| Can view, edit, update | Can VIEW only |
| Can complete or release | CANNOT edit or update |
| Full access | Use `/claim-task` to take ownership |

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
│ - 🔵 auth-refactor (YOURS)      │ - 🔵 payment-api (YOURS)        │
│ - ⚪ payment-api (other)        │ - ⚪ auth-refactor (other)      │
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

## Progress Tracking

### Source of Truth: progress.md

**`progress.md` is THE source of truth for task progress.** TodoWrite is just a UI mirror.

```markdown
# Example progress.md
- [x] Phase 1: Research
- [ ] **IN PROGRESS** → Phase 2: Implementation
- [ ] Phase 3: Testing
```

### Workflow

1. Complete work on a step
2. Update `progress.md` with `[x]`
3. Sync to TodoWrite for UI visibility
4. Update `active.md` current focus

### Why progress.md?

- **Persists across sessions** - survives /clear
- **Single source** - no sync conflicts
- **Human readable** - easy to review
- **Git trackable** - can commit progress

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
2. **Save at 70%**: Don't wait until 90% - danger is at 77.5%
3. **progress.md is truth**: Update it, sync to TodoWrite
4. **Use /active-tasks**: Know what's being worked on
5. **Complete properly**: Don't abandon tasks, use /complete-task
6. **Release when pausing**: Use /release-task for clean handoffs
7. **Respect ownership**: Never modify another session's task
8. **Large tasks are normal**: Spanning multiple sessions is expected

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

### Context warnings not appearing
- Warnings now appear at 50%, 60%, 70%, 75%
- Auto-save triggers at 75% (critical)
- Check `/context` for current usage

### Progress not syncing
- `progress.md` is source of truth, not TodoWrite
- Run `/task-status` to sync progress.md to TodoWrite
- Update progress.md first, then sync

## Documentation

See the `docs/` folder for detailed documentation:

- [State Flow Diagrams](docs/SSM-State-Flow-Diagrams.md) - Visual guide to task lifecycle and multi-session handoffs
- [Compatibility Report](docs/SSM-Compatibility-Report.md) - Integration details
- [Hypothetical Examples](docs/SSM-Hypothetical-Examples.md) - Usage scenarios
- [Multi-Instance Task Completion](docs/SSM-MultiInstance-TaskCompletion.md) - Coordination patterns

## Version History

### v2.1 (Current)
- **Session State Sync Fix**: All commands now update session-specific state files
- **LAST_ACTION Tracking**: Every significant action updates LAST_ACTION for accurate status display
- **Fixed File References**: Commands now correctly target `session-<id>.md` instead of `active.md`
- **Post-Action Sync**: Skills include explicit guidance to sync session state after actions
- **State Flow Documentation**: Added visual diagrams showing complete task lifecycle

### v2.0
- New context thresholds: 50%, 60%, 70%, 75% (was 70%, 80%, 90%)
- `progress.md` as source of truth (not TodoWrite)
- Full task structure created by default (5 files)
- Session ownership rules enforced
- Large tasks spanning sessions documented as normal
- Auto-save at 75% critical threshold
- Task detection prompting for multi-step work

### v1.0
- Initial release with basic state management
- Multi-instance support
- Compaction blocking

## License

MIT - Use freely in your projects.
