# SSM Snippet for Existing CLAUDE.md

Copy everything below the line into your existing CLAUDE.md file.

---

## Session State Manager (SSM)

This project uses the Session State Manager (SSM) for context preservation and task management across sessions.

### Core Concept

SSM prevents context degradation from auto-compaction by:
1. **Blocking auto-compaction** entirely - you control when to clear
2. **Auto-tracking working files** after every edit
3. **Proactive context warnings** at 50%, 60%, 70%, 75% thresholds (auto-save at 75%)
4. **Structured task tracking** with progress.md as source of truth
5. **Session-aware state** for multi-instance work (with ownership rules)

### SSM Commands

| Command | Purpose |
|---------|---------|
| `/new-task <id>` | Create a new task with proper structure |
| `/task-status` | Show current task progress |
| `/continue-task` | Load and resume saved state |
| `/save-state` | Save progress before `/clear` |
| `/complete-task` | Mark task done and archive |
| `/active-tasks` | View all tasks across sessions |
| `/claim-task <id>` | Take over a paused task |
| `/release-task` | Pause task, allow others to claim |
| `/task-history` | View completed tasks |
| `/ssm-status` | Show SSM status summary |

### State Files

**Session State** (`.claude/state/sessions/session-<id>.md`):
- Current task and phase
- Files to load (Immediate Context)
- Current focus and next steps
- Working files (auto-tracked)

**Task Files** (`tasks/<task-id>/`):
- `task.md` - Goal, status, metadata
- `plan.md` - Implementation phases with checkpoints
- `progress.md` - **Source of truth** for progress (synced to TodoWrite)
- `context.md` - Files to load with token estimates
- `decisions.md` - Key decisions made

All files created by default with `/new-task`. This enables effective multi-session work.

**Central Registry** (`.claude/state/active-tasks.md`):
- Tracks all active tasks across sessions
- Shows which session owns each task
- Lists paused and recently completed tasks

### Context Management Workflow

**CRITICAL: Context thresholds (adjusted for 45k buffer):**
- **< 50%**: Normal work
- **50-60%**: Good checkpoint opportunity
- **60-70%**: Plan to save soon
- **70-75%**: Finish current step, then save+clear
- **> 75%**: SAVE NOW - only 5k tokens to danger zone (77.5%)

**Save workflow:**
1. Run `/save-state` to capture progress to files
2. Run `/clear` to start fresh
3. State auto-loads on next message

**Large tasks spanning multiple sessions is NORMAL:**
```
Session 1: Phases 1-2 → save → clear
Session 2: Phases 3-4 → save → clear
Session 3: Phases 5-6 → complete
```
Progress preserved in `progress.md`. No information loss.

### Hook System

SSM uses Claude Code hooks for automatic context awareness:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `session-start.sh` | SessionStart | Loads saved state automatically |
| `context-check.sh` | UserPromptSubmit | Monitors context % and warns |
| `pre-compact.sh` | PreCompact | Blocks compaction entirely |
| `post-tool-use.sh` | PostToolUse (Edit/Write) | Auto-tracks working files |
| `track-changes.sh` | PreToolUse (Edit/Write) | Tracks modified files |
| `stop-hook.sh` | Stop | Warns if task incomplete |

### Multi-Instance Support

When running multiple Claude Code sessions:
- Each session has its own state file (`session-<id>.md`)
- Central `active-tasks.md` coordinates ownership
- **CRITICAL: Never modify tasks owned by other sessions**
- Use `/claim-task` to take over paused/stale tasks only
- Use `/release-task` to pause and allow handoff

**Session ownership rules:**
- Can only edit tasks you own (check active-tasks.md)
- Other sessions' tasks are view-only
- Use `/claim-task` to properly take ownership

### Subagents for Context Efficiency

Use subagents to keep exploration out of main context:

**Explorer** (for codebase research):
```
Task tool with subagent_type: "Explore"
```

**Planner** (for design decisions):
```
Task tool with subagent_type: "Plan"
```

### Best Practices

1. **Start with `/new-task`** for any non-trivial work
2. **Monitor context** - save/clear at 70%, not 90% (danger at 77.5%)
3. **Update progress.md** - this is the source of truth
4. **Sync to TodoWrite** - for UI visibility (mirror of progress.md)
5. **Save before switching** - run `/save-state` first
6. **One task per session** - keeps context focused
7. **Large tasks span sessions** - this is normal and expected

### Troubleshooting

**Hook errors:**
- Hooks must return valid JSON with `{"continue": true}` or `{"continue": false}`
- Check hook file permissions (should be executable)
- Test hooks manually: `echo '{"source": "startup"}' | ./.claude/hooks/session-start.sh`

**Paths with spaces:**
- If your project path contains spaces, ensure `settings.json` uses quoted paths:
  ```json
  "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/hook-name.sh\""
  ```

**State not loading:**
- Verify session state exists: `ls .claude/state/sessions/`
- Check active-tasks.md for task registration
- Run `/continue-task` to manually load

**Context warnings not showing:**
- Warnings appear at 50%, 60%, 70%, 75%
- Auto-save triggers at 75% (critical)
- Check `/context` for current usage level

**Compaction blocked message:**
- This is expected! SSM blocks auto-compaction
- Run `/save-state` then `/clear` instead
