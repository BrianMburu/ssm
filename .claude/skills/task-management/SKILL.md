---
name: task-management
description: Manages tasks and work tracking. Activates when user says "let's work on", "start", "implement", "build", "create", "fix", "add", asks about progress, or mentions tasks, features, or bugs.
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(date:*), TodoWrite
---

# Task Management Skill

Structured task tracking with progress.md as source of truth, synced to TodoWrite UI.

## CRITICAL: Session Ownership

**NEVER modify tasks owned by other sessions.**

Before ANY task operation:
1. Check `active-tasks.md` for task ownership
2. If task belongs to another session, DO NOT:
   - Edit its task files
   - Update its progress
   - Change its status
3. Only interact via `/claim-task` or `/release-task`

```bash
# Check who owns a task
grep "<task-id>" .claude/state/active-tasks.md
```

## When to Auto-Activate

This skill should activate when the user:

**Starting Work:**
- "Let's work on..." / "I want to work on..."
- "Let's implement..." / "Let's build..." / "Let's create..."
- "Start working on..." / "Begin..."
- "I need to add..." / "I need to fix..."
- "Help me with..." (when it's a concrete task)

**Checking Progress:**
- "What's the status?" / "Where are we?"
- "What's left?" / "What's next?"
- "Show progress" / "Task status"

**Task Management:**
- "New task" / "Create task"
- "Complete task" / "Finish task"
- "What am I working on?"

## Task Creation (Full Structure)

When the user wants to start work, create the complete structure:

### 1. Create Full Task Directory

```bash
mkdir -p tasks/<task-id>
```

Create ALL files using templates from `tasks/.templates/`:
- `task.md` - Goal, status, metadata
- `plan.md` - Implementation phases with checkpoints
- `progress.md` - Source of truth for progress
- `context.md` - Files to load with token estimates
- `decisions.md` - Key decisions (can start empty)

### 2. Register in active-tasks.md

Add row to "Currently Active" table with your session ID:

```markdown
| <task-id> | session-<id> | IN_PROGRESS | <timestamp> | <goal> |
```

### 3. Update Session State

Update `.claude/state/active.md`:
- Set Current Task
- Set Current Focus to first step
- Add task files to Immediate Context

### 4. Initialize TodoWrite from progress.md

Read `progress.md` and sync to TodoWrite:

```javascript
// Read progress.md checkboxes, then create matching todos
TodoWrite([
  { content: "Phase 1: Research", status: "in_progress", activeForm: "Researching" },
  { content: "Phase 2: Implementation", status: "pending", activeForm: "Implementing" },
  { content: "Phase 3: Testing", status: "pending", activeForm: "Testing" }
])
```

### 5. Start Working

After setup, begin work on first phase.

## Source of Truth: progress.md

**progress.md is THE source of truth.** TodoWrite is just a UI mirror.

### Updating Progress

1. Complete work on a step
2. Update `progress.md` with `[x]`
3. Update TodoWrite to match
4. Update `active.md` current focus

```markdown
# Example progress.md update
- [x] Phase 1: Research
- [ ] **IN PROGRESS** → Phase 2: Implementation
- [ ] Phase 3: Testing
```

### Syncing to TodoWrite

Keep TodoWrite in sync with progress.md:
- When progress.md changes, update TodoWrite
- Progress.md is authoritative if they differ

## Checking Task Status

When user asks about status:

1. Read `.claude/state/active.md` for current task
2. **Read `tasks/<id>/progress.md`** for actual progress
3. Read `tasks/<id>/plan.md` for phase details
4. Report: task name, phase, completed steps, next step

## Completing a Task

When work is done:

1. Update `progress.md` - all items `[x]`
2. Update `task.md` status to COMPLETED
3. Update TodoWrite - all completed
4. Move task in `active-tasks.md` from "Currently Active" to "Recently Completed"
5. Clear session state's Current Task
6. Suggest: "Task complete! Start a new one with /new-task or describe what's next."

## Multi-Session Awareness

### Large Tasks Span Sessions

This is NORMAL:
```
Session 1: Phases 1-2 → save → clear
Session 2: Phases 3-4 → save → clear
Session 3: Phases 5-6 → complete
```

Progress preserved in `progress.md`. No information loss.

### Context Checkpoints

Plan checkpoints at 60-70% context:
- Check `plan.md` for "Checkpoint: Yes" phases
- Save state before clearing
- Progress continues seamlessly

## Integration with Claude's Tools

**progress.md**: Source of truth for progress
**TodoWrite**: UI display (mirror of progress.md)
**Read/Write**: For task and state files

### Subagents for Context Isolation

Use subagents to keep main conversation context clean:

**Explorer Subagent** (for understanding code):
```
Task tool:
- subagent_type: "Explore"
- prompt: "Find files handling X and summarize the implementation"
- model: "haiku" (optional, for speed)
```

**Planner Subagent** (for designing approach):
```
Task tool:
- subagent_type: "Plan"
- prompt: "Design implementation plan for feature Y"
```

## Task Detection & Prompting

When user describes work but no task is active:

**Strong signals to suggest task creation:**
- Multi-step feature requests
- Bug fixes that need investigation
- Refactoring requests
- "Can you help me with..." + substantial work

**Suggest task creation:**
```
This sounds like a multi-step task. Would you like me to:
1. Create a tracked task with /new-task <suggested-id>
2. Just start working (no formal tracking)

Tracked tasks preserve progress across context clears.
```

**Skip suggestion for:**
- Quick questions or lookups
- Single-file, single-change requests
- Clarification questions
- Documentation reads

## Key Principles

1. **Session ownership** - Never modify other sessions' tasks
2. **progress.md is truth** - TodoWrite is UI mirror only
3. **Full structure** - Create all files upfront
4. **Large tasks span sessions** - This is normal, not failure
5. **Sync after changes** - Always update both progress.md AND TodoWrite
