# Project Configuration

## Session State Management

This project uses the Session State Manager (SSM) for context preservation and multi-instance coordination.

**Critical Rule**: Never let auto-compact run. Save state and `/clear` instead.

### Session Start Protocol
1. Read session state (auto-loaded by hook)
2. Load files listed in "Immediate Context"
3. Continue from current focus

### Before Clearing
1. Run `/save-state` to preserve progress
2. Commit state files if desired
3. Then run `/clear`

## Imports

@.claude/state/active.md
@.claude/rules/state-management.md
@.claude/rules/context-efficiency.md

## Project Overview

<!-- Add your project description here -->

## Tech Stack

<!-- Add your technology stack here -->
- Language: 
- Framework: 
- Database: 
- Testing: 

## Key Directories

- `src/` - Source code
- `tests/` - Test files
- `docs/` - Documentation
- `tasks/` - Task tracking (SSM)
- `.claude/state/sessions/` - Per-session state

## Built-in Commands (Use These!)

| Command | Purpose |
|---------|---------|
| `/context` | View context usage (colored grid) |
| `/todos` | List TODO/FIXME items in code |
| `/compact` | Compress context (avoid - prefer /clear) |
| `/clear` | Clear conversation, start fresh |
| `/resume` | Resume a previous conversation |
| `/rewind` | Undo recent conversation/code changes |
| `/cost` | Show token usage statistics |

## SSM Commands - Task Lifecycle

| Command | Purpose |
|---------|---------|
| `/new-task <id>` | Create new task with structure |
| `/task-status` | Show current task progress |
| `/complete-task` | Mark done, archive, summarize |
| `/task-history` | View completed tasks |

## SSM Commands - Session Management

| Command | Purpose |
|---------|---------|
| `/save-state` | Save session state before /clear |
| `/continue-task` | Continue task from saved state |
| `/ssm-status` | Show SSM status summary |

## SSM Commands - Multi-Instance

| Command | Purpose |
|---------|---------|
| `/active-tasks` | View ALL tasks across sessions |
| `/claim-task <id>` | Take over task from another session |
| `/release-task` | Pause task, allow others to claim |

## SSM Skills (Auto-Activated)

| Skill | Triggers On |
|-------|------------|
| `session-state` | Saving, loading, continuing work |
| `task-management` | Creating tasks, tracking progress |
| `context-monitor` | Context concerns, file loading |
| `multi-instance` | Parallel work, handoffs, other terminals |

## Code Style

<!-- Add your code style preferences here -->

## Testing Requirements

<!-- Add your testing requirements here -->
