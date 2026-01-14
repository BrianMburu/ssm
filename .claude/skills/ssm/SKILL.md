---
name: ssm
description: Session State Manager - unified task and context management. Activates on task-related requests (start, implement, build, fix, create), progress questions (status, what's next, done), state management (save, continue, clear), and context concerns (memory, tokens, full).
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(date:*), Bash(ls:*), TodoWrite
---

# SSM - Session State Manager

Unified skill for task management, state persistence, and context protection.

## Auto-Activation Triggers

### Starting Work
- "Let's work on..." / "Start working on..."
- "Implement..." / "Build..." / "Create..." / "Add..."
- "Fix..." / "Debug..." / "Refactor..."
- "Help me with..." (concrete tasks)

### Progress & Status
- "What's the status?" / "Where are we?"
- "What's next?" / "What's left?"
- "Am I done?" / "Is this complete?"
- "Show progress" / "Task status"

### State Management
- "Save state" / "Save progress"
- "Continue work" / "Resume"
- "Before I clear" / "Wrapping up"
- "What was I working on?"

### Context Concerns
- "Context usage?" / "How much space?"
- "Running out of memory/tokens"
- "Is it almost full?"

### Multi-Session
- "Other terminal" / "Other session"
- "What else is being worked on?"
- "Hand off" / "Take over"

## Quick Reference

### Task Commands
| Command | Purpose |
|---------|---------|
| `/start <desc>` | Start task immediately |
| `/new-task <id>` | Create task with structure |
| `/task-status` | Show current progress |
| `/complete-task` | Mark done and archive |

### State Commands
| Command | Purpose |
|---------|---------|
| `/save-state` | Save before clearing |
| `/continue-task` | Resume from saved state |
| `/clear` | Fresh context (state reloads) |

### Multi-Instance
| Command | Purpose |
|---------|---------|
| `/active-tasks` | See all tasks |
| `/claim-task <id>` | Take over task |
| `/release-task` | Pause for handoff |

## Core Workflows

### Starting a Task (Fast Path)
```
User: "Let's implement user authentication"

1. Create tasks/implement-user-auth/task.md
2. Register in active-tasks.md
3. Update session state
4. Initialize TodoWrite
5. Start exploring code immediately
```

### Saving State (Before Clear)
```
User: "I need to stop for now"

1. Update active.md with current focus
2. Update todo list state
3. Note: "Run /clear when ready"
4. State will auto-reload next session
```

### Checking Status
```
User: "What's my status?"

1. Read active.md for current task
2. Read todo list for progress
3. Report: task, completed items, next step
```

## Automatic Protections

SSM provides these automatically via hooks:

- **Compaction blocked**: PreCompact hook prevents context loss
- **Context warnings**: Alerts at 70%, 80%, 90% usage
- **Auto-save**: Working files tracked after each edit
- **State reload**: SessionStart hook loads state automatically

## Key Principles

1. **Start fast** - Task setup < 30 seconds
2. **Work, don't plan** - Begin coding immediately
3. **Save often** - Don't wait for warnings
4. **Clear, don't compact** - Preserve context quality
5. **One task per session** - Keep focus clean

## State File Locations

```
.claude/state/
├── active.md           # Current session state
├── active-tasks.md     # All tasks registry
└── sessions/           # Per-session state files
    └── session-<id>.md

tasks/<task-id>/
├── task.md             # Task goal and notes
├── plan.md             # (optional) Detailed plan
├── decisions.md        # (optional) Key decisions
└── handoffs/           # Session handoff files
```

## Integration with Claude Code

- Uses native **TodoWrite** for progress tracking
- Respects **`/context`** for usage checks
- Works with **`/clear`** for fresh starts
- Compatible with **subagents** for exploration
