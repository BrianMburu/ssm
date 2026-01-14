# Project Configuration

## Session State Management (SSM)

This project uses SSM for context preservation and multi-instance coordination.

**Critical Rule**: Never let auto-compact run. Save state and `/clear` instead.

### Workflow
- State auto-loads on session start
- Before `/clear`: run `/save-state`
- After `/clear`: state reloads automatically

## Project Overview

<!-- Add your project description here -->

## Tech Stack

<!-- Add your tech stack here -->

## Key Directories

- `src/` - Source code
- `tests/` - Test files
- `tasks/` - Task tracking (SSM)

## Commands

### SSM Commands
| Command | Purpose |
|---------|---------|
| `/new-task <id>` | Create new task |
| `/save-state` | Save before clearing |
| `/continue-task` | Resume from saved state |
| `/ssm-status` | Show SSM status |
| `/active-tasks` | View all tasks |

### Built-in Commands
| Command | Purpose |
|---------|---------|
| `/context` | View context usage |
| `/clear` | Fresh context |
| `/resume` | Resume conversation |

## Code Style

<!-- Add your code style preferences here -->

## Testing

<!-- Add your testing requirements here -->
