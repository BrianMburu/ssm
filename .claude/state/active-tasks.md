# Active Tasks Registry

Central registry tracking all active and recently completed tasks across sessions.

Last Updated: <!-- Auto-updated by SSM -->
Updated by: <!-- Session ID that last modified -->

## Currently Active

| Task ID | Session | Started | Phase | Status |
|---------|---------|---------|-------|--------|
| session-id-bug | 828334 | 2026-01-14 | Complete | COMPLETED |

## Paused Tasks

| Task ID | Last Session | Paused Since | Phase | Reason |
|---------|--------------|--------------|-------|--------|
| <!-- Paused tasks listed here --> |

## Recently Completed (Last 14 Days)

| Task ID | Completed | Duration | Sessions | Outcome |
|---------|-----------|----------|----------|---------|
| <!-- Completed tasks listed here --> |

---

## Registry Rules

1. **One task per session**: A task can only be actively worked on by one session
2. **Claiming**: Use `/claim-task <id>` to take over a paused task
3. **Releasing**: Use `/release-task` to pause and allow others to claim
4. **Completing**: Use `/complete-task` to mark done and archive

## Session States

- **ACTIVE**: Session is currently working on the task
- **PAUSED**: Task is on hold, can be claimed by another session
- **QUICK_FIX**: Temporary access without full claim (for small fixes)

## Notes

<!-- Add any cross-task dependencies or notes here -->
