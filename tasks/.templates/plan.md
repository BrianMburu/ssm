# Implementation Plan: {{TASK_ID}}

Created: {{TIMESTAMP}}
Goal: {{GOAL}}

## Overview

{{GOAL_DESCRIPTION}}

## Context Budget

**Important**: Large tasks span multiple sessions. Plan checkpoints accordingly.

| Phase | Est. Tokens | Checkpoint? |
|-------|-------------|-------------|
| Phase 1 | ~Xk | No |
| Phase 2 | ~Xk | **Yes** - good save point |
| Phase 3 | ~Xk | No |
| Phase 4 | ~Xk | **Yes** - save before testing |

**Recommended session breaks**: After Phase 2, After Phase 4

## Prerequisites

- [ ] Understand current implementation
- [ ] Identify affected files
- [ ] Review related tests

## Implementation Phases

### Phase 1: Research & Understanding
**Checkpoint**: No (typically quick)
**Estimated context**: ~20-30k tokens

1. [ ] Explore relevant codebase areas
2. [ ] Identify files to modify
3. [ ] Understand existing patterns
4. [ ] Document findings in context.md

### Phase 2: Core Implementation
**Checkpoint**: **Yes** - save after this phase
**Estimated context**: ~40-50k tokens cumulative

1. [ ] Implement main functionality
2. [ ] Update related files
3. [ ] Handle edge cases

### Phase 3: Testing & Validation
**Checkpoint**: Optional
**Estimated context**: ~30k additional

1. [ ] Write/update tests
2. [ ] Run test suite
3. [ ] Fix any failures

### Phase 4: Cleanup & Documentation
**Checkpoint**: **Yes** - final save point
**Estimated context**: ~20k additional

1. [ ] Code cleanup
2. [ ] Update documentation
3. [ ] Final review

## Acceptance Criteria

- [ ] Core functionality works
- [ ] Tests pass
- [ ] No regressions
- [ ] Code reviewed

## Technical Notes

<!-- Architecture considerations, patterns to follow, constraints -->

## Out of Scope

<!-- Explicitly what this task does NOT include -->

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Context overflow | Medium | Plan checkpoints at 60-70% |
| Complex dependencies | Low | Research phase first |

## References

<!-- Links to relevant docs, issues, PRs -->
