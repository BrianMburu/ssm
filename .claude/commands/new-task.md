---
name: new-task
argument-hint: <task-id>
description: Create a new task with proper structure. Registers in active-tasks.md and creates session state.
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(cat:*), Bash(date:*)
---

# Create New Task: $ARGUMENTS

Setting up task structure, session state, and registry entry.

## Step 1: Validate and Setup

```bash
TASK_ID="$ARGUMENTS"
TASK_DIR="tasks/$TASK_ID"
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
TIMESTAMP=$(date -Iseconds)
DATE=$(date +%Y-%m-%d)

# Check if task already exists
if [ -d "$TASK_DIR" ]; then
    echo "Task '$TASK_ID' already exists!"
    echo "Use /claim-task $TASK_ID to take it over."
    exit 1
fi

# Create directories
mkdir -p "$TASK_DIR/handoffs"
mkdir -p ".claude/state/sessions"
```

## Step 2: Create Task Files from Templates

### Plan File (`tasks/<id>/plan.md`)

```markdown
# Implementation Plan: <task-id>

Created: <timestamp>
Owner: <session-id>

## Goal

<!-- What is this task trying to achieve? Be specific. -->

## Background

<!-- Why is this task needed? Context for future readers. -->

## Prerequisites

<!-- What must be true/done before starting? -->
- [ ] Prerequisite 1
- [ ] Prerequisite 2

## Implementation Steps

### Phase 1: Planning
1. [ ] Define detailed requirements
2. [ ] Identify affected files
3. [ ] Design approach

### Phase 2: Implementation
4. [ ] Step description
5. [ ] Step description
6. [ ] Step description

### Phase 3: Verification
7. [ ] Write tests
8. [ ] Run tests
9. [ ] Code review

## Acceptance Criteria

<!-- How do we know this task is complete? -->
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] All tests pass
- [ ] No regressions

## Technical Notes

<!-- Any technical context or constraints -->

## Out of Scope

<!-- Explicitly what this task does NOT include -->

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Risk 1 | Mitigation 1 |
```

### Progress File (`tasks/<id>/progress.md`)

```markdown
# Task Progress: <task-id>

Status: NOT_STARTED
Started: <timestamp>
Last Updated: <timestamp>
Current Session: <session-id>

## Progress Tracking

### Prerequisites
- [ ] Prerequisite 1
- [ ] Prerequisite 2

### Implementation
- [ ] **NEXT** → First step
- [ ] Second step
- [ ] Third step

### Verification
- [ ] Tests written
- [ ] Tests passing
- [ ] Reviewed

## Session Log

| Date | Session | Duration | Progress |
|------|---------|----------|----------|
| <date> | <session-id> | - | Task created |

## Blockers

<!-- Current blockers -->

## Notes

<!-- Running notes about the task -->
```

### Context File (`tasks/<id>/context.md`)

```markdown
# Context Requirements: <task-id>

## Essential Files (Always Load)

| File | Tokens (est.) | Reason |
|------|--------------|--------|
| tasks/<id>/plan.md | ~500 | Current plan |
| <!-- file --> | <!-- tokens --> | <!-- reason --> |

## Reference Files (Load on Demand)

| File | Tokens (est.) | When Needed |
|------|--------------|-------------|
| tasks/<id>/decisions.md | ~200 | When making decisions |

## Deprecated Files (Never Load)

<!-- Files that are outdated or already processed -->

## Token Budget

- Essential context: ~X tokens
- Maximum recommended: ~5,000 tokens
- Current usage: TBD

## Related Code Locations

<!-- Key areas of the codebase for this task -->
```

### Decisions File (`tasks/<id>/decisions.md`)

```markdown
# Key Decisions: <task-id>

## Decision Log

### Decision 1: [Title]

**Date**: <date>
**Status**: PROPOSED | DECIDED | IMPLEMENTED
**Deciders**: <who made the decision>

**Context**: 
What prompted this decision?

**Options Considered**:
1. Option A - pros/cons
2. Option B - pros/cons

**Decision**: 
What was decided?

**Rationale**: 
Why this choice?

**Consequences**: 
What does this mean going forward?

---

<!-- Add more decisions as needed using the template above -->
```

## Step 3: Register in Active Tasks

Add entry to `.claude/state/active-tasks.md`:

```markdown
## Currently Active

| Task ID | Session | Started | Phase | Status |
|---------|---------|---------|-------|--------|
| <task-id> | <session-id> | <date> | Planning | ACTIVE |
```

## Step 4: Create Session State

Create `.claude/state/sessions/session-<id>.md`:

```markdown
# Session State: <session-id>

Created: <timestamp>
Updated: <timestamp>
Terminal: Current

## Current Task
<task-id>

## Status
PHASE: Planning
STEP: 0 of 0
BLOCKED: No
LAST_ACTION: Task created

## Immediate Context (Load These)
- tasks/<task-id>/plan.md (define the plan)
- tasks/<task-id>/progress.md (track progress)

## Do NOT Load
<!-- Nothing yet -->

## Working Files (Modified This Session)
<!-- None yet -->

## Current Focus
Define the implementation plan for <task-id>

## Next Steps
1. [ ] Define clear goal
2. [ ] List prerequisites  
3. [ ] Create implementation steps
4. [ ] Set acceptance criteria
5. [ ] Begin implementation

## Key Decisions This Session
<!-- None yet -->

## Blockers / Questions
<!-- None yet -->

## Session Log
| Timestamp | Action | Notes |
|-----------|--------|-------|
| <timestamp> | Task Created | New task: <task-id> |
```

## Step 5: Update Context Registry

Add section to `.claude/state/context-registry.md`:

```markdown
## Task: <task-id>

### Essential (Always Load)
| File | Tokens | Notes |
|------|--------|-------|
| tasks/<task-id>/plan.md | ~500 | Implementation plan |
| tasks/<task-id>/progress.md | ~300 | Current progress |

### Reference (Load on Demand)
| File | Tokens | Notes |
|------|--------|-------|
| tasks/<task-id>/context.md | ~200 | File requirements |
| tasks/<task-id>/decisions.md | ~200 | Key decisions |

### Deprecated (Never Load)
<!-- Will be populated as task progresses -->
```

## Step 6: Begin Planning

Now help the user define the task by asking:

1. **What is the specific goal?**
   What should be true when this task is complete?

2. **What files will be involved?**
   Which parts of the codebase are affected?

3. **What are the implementation steps?**
   Break down into concrete actions.

4. **What are the acceptance criteria?**
   How do we verify success?

After gathering answers, update plan.md with the concrete details.

## Summary

Task created with:
- ✅ Task directory: `tasks/<task-id>/`
- ✅ Plan, progress, context, decisions files
- ✅ Registered in active-tasks.md
- ✅ Session state created
- ✅ Context registry updated

Ready to begin planning!
