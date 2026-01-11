# Active Session State

This file serves as:
1. **Single-instance mode**: Primary state file when running one Claude instance
2. **Fallback**: Used when session ID cannot be determined
3. **Template**: Reference for session-specific state files

For multi-instance work, session-specific files are created in:
`.claude/state/sessions/session-<id>.md`

---

Updated: <!-- ISO 8601 timestamp -->
Session: <!-- Session identifier or "default" -->

## Current Task

<!-- Task ID from tasks/ directory, or "none" -->

## Status

PHASE: <!-- Current phase name -->
STEP: <!-- X of Y -->
BLOCKED: <!-- Yes/No - if Yes, describe in Blockers section -->
LAST_ACTION: <!-- What was just completed -->

## Immediate Context (Load These)

<!-- Files essential for current work -->
- <!-- filepath (reason) -->

## Do NOT Load (Already Processed)

<!-- Files that don't need to be in context -->
- <!-- filepath -->

## Working Files (Modified This Session)

<!-- Auto-tracked by track-changes hook -->
- <!-- filepath -->

## Current Focus

<!-- One clear sentence describing the immediate next action -->

## Next Steps

<!-- Ordered checklist of upcoming work -->
1. [ ] <!-- Next item -->
2. [ ] <!-- Following item -->

## Key Decisions This Session

<!-- Important decisions made, with brief rationale -->
- <!-- Decision: Rationale -->

## Blockers / Questions

<!-- Anything preventing progress -->
- <!-- Blocker or question -->

## Session History

| Timestamp | Action | Notes |
|-----------|--------|-------|
| <!-- ISO timestamp --> | <!-- action --> | <!-- notes --> |

---

## Multi-Instance Notes

When running multiple Claude instances:
- Each instance gets its own session file in `sessions/`
- The `active-tasks.md` registry tracks which session owns which task
- Use `/active-tasks` to see all work in progress
- Use `/claim-task` and `/release-task` to coordinate
