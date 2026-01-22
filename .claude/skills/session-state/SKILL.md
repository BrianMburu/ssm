---
name: session-state
description: Saves and loads session state. Activates on "save state", "save progress", "before clear", "continue work", "pick up where", "resume", "what was I working on", or when context is high and user should save.
allowed-tools: Read, Write, Edit, Bash(date:*)
---

# Session State Skill

Maintains task continuity across sessions by managing state files.

## When to Auto-Activate

**Saving State:**
- "Save state" / "Save progress" / "Save my work"
- "Before I clear" / "Before clearing"
- "I need to stop" / "Wrapping up"
- "Let me save" / "Preserve progress"

**Loading State:**
- "Continue work" / "Continue where I left off"
- "Pick up where" / "Resume work"
- "What was I working on?"
- "Load my state" / "Reload state"

**Context Warnings:**
- When context usage is high (70%+), suggest saving
- Before any `/clear` operation

## State File Location

**Default**: `.claude/state/sessions/session-<id>.md` (session-specific)
**Fallback**: `.claude/state/active.md` (only if session ID unavailable)

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
SESSION_STATE=".claude/state/sessions/session-$SESSION_ID.md"
echo "Session ID: $SESSION_ID"  # Should show a number like 828334
```

**Always use session-specific files for multi-instance support.**

**⚠️ CRITICAL**: When writing session IDs to files (state files, registry, etc.),
always use the actual NUMERIC session ID (e.g., "828334"), NEVER literal words
like "current", "this", or "default". Literal strings cause multi-session collisions.

## Saving State (Quick)

Update state file with:

```markdown
Updated: <now>
Session: <session-id>

## Current Task
<task-id>

## Status
PHASE: <current phase>
BLOCKED: No
LAST_ACTION: <what was just completed>

## Current Focus
<next action to take>

## Next Steps
1. [ ] <next item>
2. [ ] <following item>
```

Also update the todo list to reflect current progress.

## Loading State (Quick)

1. Determine session state file:
   ```bash
   SESSION_STATE=".claude/state/sessions/session-${CLAUDE_SESSION_ID:-$PPID}.md"
   ```
2. Read `$SESSION_STATE` (fall back to `active.md` if not found)
3. Show: Task, Phase, Current Focus
4. Load files from "Immediate Context"
5. Report: "Continuing <task>. Next: <focus>"

## Integration

- **Auto-save**: PostToolUse hook tracks Working Files automatically
- **Context warnings**: Hook warns at 50%, 60%, 70%, 75% (CRITICAL)
- **Compaction blocked**: PreCompact hook blocks, suggests save+clear

## State Sync Checklist

After ANY significant action, update session state:

```markdown
LAST_ACTION: <what was just completed>
Updated: <timestamp>
```

And add to Session History:
```markdown
| <timestamp> | <action> | <notes> |
```

**Significant actions requiring state sync:**
- Task creation / completion
- Task claim / release
- Step completion
- State save

## Key Commands

| Command | Purpose |
|---------|---------|
| `/save-state` | Save before clearing |
| `/continue-task` | Load and continue |
| `/clear` | Clear context (state reloads) |
