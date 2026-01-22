---
name: new-task
argument-hint: <task-id> [goal description]
description: Create a new task with full structure for effective multi-session work.
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(date:*), Bash(cp:*), TodoWrite, Task
---

# Create New Task

Create task: **$ARGUMENTS**

## Step 1: Parse Arguments

```
Input: "$ARGUMENTS"

Examples:
- "auth-refactor" → ID: auth-refactor, Goal: (ask user)
- "add user authentication" → ID: add-user-auth, Goal: Add user authentication
- "fix-login-bug fix the login redirect issue" → ID: fix-login-bug, Goal: Fix the login redirect issue
```

If only ID provided, ask user for goal before proceeding.

## Step 2: Handle Existing Session Task

Before creating, check if this session has an active task:

1. Read `.claude/state/active-tasks.md`
2. Find tasks owned by THIS session (match `$CLAUDE_SESSION_ID`)
3. If found, mark ONLY those as PAUSED (don't touch other sessions' tasks)
4. Update the registry

**Important**: Never modify tasks owned by other sessions!

## Step 3: Create Full Task Structure

```bash
TASK_ID="<extracted-task-id>"
TIMESTAMP=$(date -Iseconds)
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
DATE=$(date +%Y-%m-%d)

mkdir -p "tasks/$TASK_ID"
```

Create ALL of these files (full structure, not minimal):

### tasks/<task-id>/task.md
```markdown
# Task: <task-id>

Created: <TIMESTAMP>
Status: IN_PROGRESS
Session: <SESSION_ID>
Owner: <SESSION_ID>

## Goal

<Clear goal statement>

## Quick Links

- [Plan](./plan.md) - Implementation phases and checkpoints
- [Progress](./progress.md) - Detailed progress tracking (source of truth)
- [Context](./context.md) - Files to load, token estimates
- [Decisions](./decisions.md) - Key decisions made

## Metadata

| Field | Value |
|-------|-------|
| Created | <TIMESTAMP> |
| Started | <TIMESTAMP> |
| Last Updated | <TIMESTAMP> |
| Current Phase | 1 |
| Sessions Used | 1 |

## Notes

<!-- Running notes -->

---

## Status History

| Timestamp | Status | Session | Notes |
|-----------|--------|---------|-------|
| <TIMESTAMP> | IN_PROGRESS | <SESSION_ID> | Task created |
```

### tasks/<task-id>/plan.md

Use the Plan subagent to generate an initial plan:

```
Task tool:
- subagent_type: "Plan"
- prompt: "Create an implementation plan for: <GOAL>. Include 3-4 phases with estimated token usage and checkpoint recommendations. Format with phases, steps, acceptance criteria."
```

If Plan subagent unavailable, create basic structure:
```markdown
# Implementation Plan: <task-id>

Created: <TIMESTAMP>
Goal: <GOAL>

## Context Budget

| Phase | Est. Tokens | Checkpoint? |
|-------|-------------|-------------|
| Phase 1: Research | ~30k | No |
| Phase 2: Implementation | ~50k | **Yes** |
| Phase 3: Testing | ~30k | Optional |
| Phase 4: Cleanup | ~20k | **Yes** |

## Phases

### Phase 1: Research & Understanding
1. [ ] Explore relevant code
2. [ ] Identify files to modify
3. [ ] Document in context.md

### Phase 2: Core Implementation
1. [ ] Implement main changes
2. [ ] Update related files

### Phase 3: Testing
1. [ ] Write/update tests
2. [ ] Verify functionality

### Phase 4: Cleanup
1. [ ] Code cleanup
2. [ ] Update docs

## Acceptance Criteria
- [ ] Goal achieved
- [ ] Tests pass
- [ ] No regressions
```

### tasks/<task-id>/progress.md
```markdown
# Progress: <task-id>

**Status**: IN_PROGRESS
**Current Phase**: 1
**Started**: <TIMESTAMP>
**Last Updated**: <TIMESTAMP>

## Important

**This file is the source of truth for progress tracking.**

## Progress Overview

| Phase | Status | Steps Done |
|-------|--------|------------|
| Phase 1 | IN_PROGRESS | 0/3 |
| Phase 2 | NOT_STARTED | 0/2 |
| Phase 3 | NOT_STARTED | 0/2 |
| Phase 4 | NOT_STARTED | 0/2 |

## Detailed Progress

### Phase 1: Research
- [ ] **NEXT** → Explore relevant code
- [ ] Identify files to modify
- [ ] Document in context.md

### Phase 2: Implementation
- [ ] Implement main changes
- [ ] Update related files

### Phase 3: Testing
- [ ] Write/update tests
- [ ] Verify functionality

### Phase 4: Cleanup
- [ ] Code cleanup
- [ ] Update docs

## Session Log

| Session | Date | Phases | Notes |
|---------|------|--------|-------|
| <SESSION_ID> | <DATE> | 1 | Task created |
```

### tasks/<task-id>/context.md
```markdown
# Context: <task-id>

## Essential Files

| File | Est. Tokens | Reason |
|------|-------------|--------|
| <!-- Add during research --> | | |

## Do NOT Load

| File | Reason |
|------|--------|
| node_modules/* | Never |
| dist/* | Build output |
```

### tasks/<task-id>/decisions.md
```markdown
# Decisions: <task-id>

## Decision Log

No decisions yet. Add as they arise.

## Pending Decisions

- [ ] Any architectural questions to resolve?
```

## Step 4: Register Task

**First, get the actual session ID:**
```bash
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
echo "Session ID: $SESSION_ID"  # Should show a number like 828334
```

Add to `.claude/state/active-tasks.md` under "Currently Active":

```markdown
| <task-id> | 828334 | IN_PROGRESS | 2026-01-14 | Phase 1 |
```
(Replace 828334 with your actual `$SESSION_ID` numeric value)

**⚠️ CRITICAL**: The Session column MUST contain the actual NUMERIC session ID
(e.g., "828334"), NOT literal words like "current", "new", or "default".
Literal strings cause session collisions when running multiple instances.

**Important**: Preserve all other rows. Only add this new row.

## Step 5: Update Session State (CRITICAL)

**IMPORTANT**: Update the SESSION-SPECIFIC state file, not active.md.

```bash
SESSION_ID="${CLAUDE_SESSION_ID:-$PPID}"
SESSION_STATE=".claude/state/sessions/session-$SESSION_ID.md"
```

Update `$SESSION_STATE` with:

```markdown
## Current Task
<task-id>

## Status
PHASE: Phase 1 - Research
STEP: 1
BLOCKED: No
LAST_ACTION: Created task <task-id> with full structure

## Immediate Context (Load These)
- tasks/<task-id>/plan.md
- tasks/<task-id>/progress.md
- tasks/<task-id>/context.md

## Current Focus
Begin Phase 1: Research and understand the codebase for <GOAL>

## Next Steps
1. [ ] **NEXT** → Explore relevant code
2. [ ] Identify files to modify
3. [ ] Document findings in context.md
```

Also add entry to Session History:
```markdown
| <timestamp> | Task created | Created <task-id> with full structure |
```

## Step 6: Initialize TodoWrite

Sync progress.md to TodoWrite for UI visibility:

```javascript
TodoWrite([
  { content: "Phase 1: Explore relevant code", status: "in_progress", activeForm: "Exploring code" },
  { content: "Phase 1: Identify files to modify", status: "pending", activeForm: "Identifying files" },
  { content: "Phase 1: Document in context.md", status: "pending", activeForm: "Documenting context" },
  { content: "Phase 2: Implement main changes", status: "pending", activeForm: "Implementing" },
  { content: "Phase 3: Write/update tests", status: "pending", activeForm: "Testing" },
  { content: "Phase 4: Cleanup and docs", status: "pending", activeForm: "Cleaning up" }
])
```

## Step 7: Output and Begin

Show:
```
✅ Task created: <task-id>

Goal: <GOAL>

Structure created:
  tasks/<task-id>/
  ├── task.md      ← Metadata and status
  ├── plan.md      ← Implementation phases
  ├── progress.md  ← Progress tracking (source of truth)
  ├── context.md   ← Files to load
  └── decisions.md ← Key decisions

Current phase: Phase 1 - Research
First step: Explore relevant code

Ready to begin. What area of the codebase should we explore first?
```

Then immediately help the user start Phase 1.

## Key Principles

1. **Full structure by default** - All files created, not "progressive disclosure"
2. **progress.md is truth** - TodoWrite mirrors it but may lag
3. **Plan has checkpoints** - Know where to save+clear
4. **Session ownership** - Only modify this session's tasks
5. **Start immediately** - Setup done, begin working
