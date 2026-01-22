# Implementation Plan: session-id-bug

Created: 2026-01-14T21:32:13+03:00
Goal: Fix session ID defaulting to 'default' instead of unique values

## Context Budget

| Phase | Est. Tokens | Checkpoint? |
|-------|-------------|-------------|
| Phase 1: Diagnosis | ~20k | No |
| Phase 2: Root Cause Analysis | ~30k | **Yes** |
| Phase 3: Fix Implementation | ~30k | **Yes** |
| Phase 4: Verification | ~20k | **Yes** |

## Phases

### Phase 1: Diagnosis
1. [ ] Check how CLAUDE_SESSION_ID is supposed to be set
2. [ ] Examine session-start.sh hook logic
3. [ ] Check settings.json hook registration
4. [ ] Identify where the variable should be exported

### Phase 2: Root Cause Analysis
1. [ ] Determine if Claude Code sets CLAUDE_SESSION_ID automatically
2. [ ] Check if hooks can export variables to the session
3. [ ] Review Claude Code documentation on session IDs
4. [ ] Document the actual vs expected behavior

### Phase 3: Fix Implementation
1. [ ] Implement correct session ID generation/retrieval
2. [ ] Update relevant hooks and scripts
3. [ ] Ensure session state files use correct IDs

### Phase 4: Verification
1. [ ] Test session ID generation
2. [ ] Verify multi-instance scenarios work
3. [ ] Update documentation if needed

## Acceptance Criteria
- [ ] Session ID is unique per Claude Code instance
- [ ] Session state files created with correct session ID
- [ ] No session collisions possible
- [ ] Documentation reflects actual behavior
