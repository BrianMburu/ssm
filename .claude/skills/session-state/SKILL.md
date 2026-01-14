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

Primary: `.claude/state/active.md`
Per-session: `.claude/state/sessions/session-<id>.md`

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

1. Read `.claude/state/active.md`
2. Show: Task, Phase, Current Focus
3. Load files from "Immediate Context"
4. Report: "Continuing <task>. Next: <focus>"

## Integration

- **Auto-save**: PostToolUse hook tracks Working Files automatically
- **Context warnings**: Hook warns at 70%, 80%, 90%
- **Compaction blocked**: PreCompact hook blocks, suggests save+clear

## Key Commands

| Command | Purpose |
|---------|---------|
| `/save-state` | Save before clearing |
| `/continue-task` | Load and continue |
| `/clear` | Clear context (state reloads) |
