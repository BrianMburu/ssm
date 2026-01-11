---
name: session-state-manager
description: Manages session state for task continuity. Use when starting work, before clearing context, when context is getting high, or when the user mentions saving progress, state, or continuity.
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(date:*), Bash(grep:*)
---

# Session State Manager Skill

This skill helps maintain task continuity across sessions by managing state files.

## When to Activate

Automatically activate when:
- Starting a new session (check for existing state)
- User mentions "save state", "save progress", "before clearing"
- Context usage appears high (suggest saving)
- User asks to "continue", "pick up", or "resume" work
- Before any `/clear` operation

## State Files

The source of truth is `.claude/state/active.md`. This file contains:
- Current task identifier
- Phase and step progress
- Files to load (Immediate Context)
- Current focus description
- Next steps checklist

## Loading State

When starting work or continuing:

1. Read `.claude/state/active.md`
2. Extract the Current Task ID
3. Load files listed in "Immediate Context"
4. If a task is active, also read `tasks/<task-id>/progress.md`

```bash
cat .claude/state/active.md
```

## Saving State

Before `/clear` or when context is high:

1. Update `.claude/state/active.md` with:
   - Current timestamp
   - PHASE and STEP progress
   - LAST_ACTION completed
   - Files in Immediate Context (what to reload)
   - Current Focus (next action)
   - Next Steps (remaining work)

2. Update task progress file if applicable:
   - Check off completed items: `[x]`
   - Mark current item: `[ ] **IN PROGRESS** →`

## State File Template

```markdown
# Active Session State
Updated: [ISO timestamp]
Session: [identifier]

## Current Task
[task-id]

## Status
PHASE: [phase name]
STEP: [X] of [Y]
BLOCKED: [Yes/No]
LAST_ACTION: [what was just done]

## Immediate Context (Load These)
- [file path] (reason)

## Current Focus
[One clear sentence about immediate next action]

## Next Steps
1. [ ] [next item]
2. [ ] [following item]
```

## Integration with Built-in Commands

- Use `/context` to check current context usage
- Use `/compact` only as last resort (prefer save + `/clear`)
- Use `/todos` to see task items (integrates with our progress tracking)
