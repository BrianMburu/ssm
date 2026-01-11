# Task Template

Copy this template when creating a new task manually (or use `/new-task`).

---

## Directory Structure

```
tasks/<task-id>/
├── plan.md         # Implementation plan (required)
├── progress.md     # Checklist with status (required)
├── context.md      # Required files for task (recommended)
├── decisions.md    # Key decisions & rationale (recommended)
└── handoffs/       # Session handoffs (auto-created)
```

---

## plan.md Template

```markdown
# Implementation Plan: [Task Name]

Created: [timestamp]
Author: [name/claude]

## Goal

[Clear, specific statement of what this task achieves]

## Background

[Why is this task needed? What problem does it solve?]

## Prerequisites

- [ ] [What must be done/true before starting]
- [ ] [Dependencies, setup, research]

## Implementation Steps

### Phase 1: [Phase Name]

1. [ ] [Specific, actionable step]
   - Details or sub-steps if needed
   
2. [ ] [Next step]

3. [ ] [Continue...]

### Phase 2: [Phase Name]

4. [ ] [Continue numbering across phases]

5. [ ] [etc.]

## Acceptance Criteria

- [ ] [How do we know this is done?]
- [ ] [Measurable, testable criteria]
- [ ] All tests pass
- [ ] Code reviewed
- [ ] No regressions

## Technical Notes

[Architecture considerations, patterns to follow, constraints]

## Out of Scope

[Explicitly what this task does NOT include]

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | [H/M/L] | [H/M/L] | [How to address] |

## References

- [Links to relevant docs, issues, PRs]
```

---

## progress.md Template

```markdown
# Task Progress: [Task ID]

Status: NOT_STARTED
Started: [timestamp]
Last Updated: [timestamp]
Estimated Completion: [date]

## Progress Tracking

### Prerequisites
- [ ] [item]
- [ ] [item]

### Phase 1: [Name]
- [ ] **NEXT** → [First step]
- [ ] [Second step]
- [ ] [Third step]

### Phase 2: [Name]
- [ ] [Step]
- [ ] [Step]

### Verification
- [ ] Tests written
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Documentation updated

## Session Log

| Date | Session ID | Progress | Notes |
|------|------------|----------|-------|
| [date] | [id] | Task created | Initial setup |

## Blockers

<!-- Active blockers preventing progress -->

## Notes

<!-- Running notes, observations, things to remember -->
```

---

## context.md Template

```markdown
# Context Requirements: [Task ID]

## Essential Files (Always Load)

<!-- Core files needed for this task -->
| File | Tokens (est.) | Reason |
|------|---------------|--------|
| src/path/file.ts | ~300 | Main file being modified |
| src/types/index.ts | ~150 | Type definitions |

**Total Essential**: ~450 tokens

## Reference Files (Load on Demand)

<!-- Supporting files, load when specifically needed -->
| File | Tokens (est.) | When to Load |
|------|---------------|--------------|
| docs/design.md | ~500 | During planning phase |
| tests/example.test.ts | ~200 | When writing tests |

## Deprecated Files (Never Load)

<!-- Old files to avoid - saves tokens and prevents confusion -->
- src/old-implementation.ts (replaced by new-implementation.ts)
- docs/outdated-design.md (see docs/design.md instead)

## Related Code Locations

<!-- Key places in codebase, for quick reference -->
- Authentication: src/auth/
- API handlers: src/api/
- Shared types: src/types/

## External Resources

<!-- Links to docs, APIs, etc. -->
- [API Documentation](url)
- [Design Spec](url)
```

---

## decisions.md Template

```markdown
# Key Decisions: [Task ID]

## Decision Log

### ADR-001: [Decision Title]

**Date**: [YYYY-MM-DD]
**Status**: PROPOSED | DECIDED | IMPLEMENTED | DEPRECATED
**Deciders**: [Who made this decision]

**Context**:
[What is the situation? What prompted this decision?]

**Options Considered**:

1. **Option A**: [Description]
   - ✅ Pros: [advantages]
   - ❌ Cons: [disadvantages]

2. **Option B**: [Description]
   - ✅ Pros: [advantages]
   - ❌ Cons: [disadvantages]

3. **Option C**: [Description]
   - ✅ Pros: [advantages]
   - ❌ Cons: [disadvantages]

**Decision**:
[What was decided and why]

**Consequences**:
- [What does this mean going forward?]
- [What must be done as a result?]
- [What constraints does this create?]

---

### ADR-002: [Next Decision]

[Continue with same format...]
```
