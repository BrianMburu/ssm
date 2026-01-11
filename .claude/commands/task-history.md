---
name: task-history
argument-hint: [task-id]
description: View completed/archived tasks. Optionally provide a task ID to see details.
allowed-tools: Read, Bash(cat:*), Bash(ls:*), Bash(find:*)
---

# Task History

View completed and archived tasks, with optional details for specific tasks.

## Usage

```
/task-history              # List all completed tasks
/task-history <task-id>    # Show details for specific task
```

## List All Completed Tasks

```bash
# List archived task directories
ls -la .claude/state/completed/

# Get summary info from each
for dir in .claude/state/completed/*/; do
  if [ -f "$dir/summary.md" ]; then
    echo "=== $(basename $dir) ==="
    head -20 "$dir/summary.md"
  fi
done
```

### Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 TASK HISTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Completed Tasks** (most recent first):

┌─ auth-refactor (Jan 11, 2026) ────────────────────────┐
│ ✅ Completed in 2 days (5 sessions)                    │
│ Goal: Replace legacy session-based auth with JWT      │
│ Files: 8 created, 3 modified                          │
│ View: /task-history auth-refactor                     │
└────────────────────────────────────────────────────────┘

┌─ user-dashboard (Jan 9, 2026) ────────────────────────┐
│ ✅ Completed in 3 days (7 sessions)                    │
│ Goal: Build user dashboard with analytics             │
│ Files: 12 created, 5 modified                         │
│ View: /task-history user-dashboard                    │
└────────────────────────────────────────────────────────┘

┌─ api-rate-limiting (Jan 5, 2026) ─────────────────────┐
│ ✅ Completed in 1 day (2 sessions)                     │
│ Goal: Implement rate limiting middleware              │
│ Files: 3 created, 2 modified                          │
│ View: /task-history api-rate-limiting                 │
└────────────────────────────────────────────────────────┘

**Statistics**:
• Total Completed: 15 tasks
• This Month: 3 tasks
• Average Duration: 2.1 days

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## View Specific Task Details

When a task ID is provided:

```bash
# Find the archived task
ARCHIVE_DIR=$(find .claude/state/completed -maxdepth 1 -type d -name "$ARGUMENTS*" | head -1)

if [ -n "$ARCHIVE_DIR" ]; then
  cat "$ARCHIVE_DIR/summary.md"
fi
```

### Detailed Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TASK DETAILS: auth-refactor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Overview**
• Goal: Replace legacy session-based auth with JWT
• Started: January 10, 2026
• Completed: January 11, 2026
• Duration: 2 days
• Sessions: 5
• Outcome: ✅ Success

**Progress**
• Steps: 7/7 (100%)
• Phases: Planning → Implementation → Verification

**Acceptance Criteria**
✅ All unit tests pass
✅ All integration tests pass
✅ No regression in existing functionality
✅ Token refresh works transparently
✅ Migration script tested

**Files Created/Modified**
Created:
  • src/auth/AuthProvider.tsx
  • src/auth/types.ts
  • src/auth/useAuth.ts
  • tests/auth/AuthProvider.test.tsx
  • tests/auth/integration.test.tsx
  • scripts/migrate-sessions.ts

Modified:
  • src/api/client.ts
  • src/middleware/auth.ts
  • package.json

**Key Decisions**
1. Used httpOnly cookies for refresh tokens
   Rationale: Better security than localStorage

2. 15-minute access token expiry
   Rationale: Balance between security and UX

3. Silent refresh via interceptor
   Rationale: Seamless user experience

**Session History**
| Session | Date | Duration | Actions |
|---------|------|----------|---------|
| abc123 | Jan 10 | 2h | Planning, initial setup |
| abc124 | Jan 10 | 3h | AuthProvider implementation |
| abc125 | Jan 11 | 1.5h | Unit tests |
| abc126 | Jan 11 | 2h | Integration tests |
| abc127 | Jan 11 | 1h | Migration script, completion |

**Archived Files**
Location: .claude/state/completed/auth-refactor-2026-01-11/
• summary.md
• plan.md (original plan)
• progress.md (final state)
• decisions.md
• sessions/ (all session states)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Actions**:
• Review archived files: cat .claude/state/completed/auth-refactor-2026-01-11/<file>
• Similar new task: /new-task auth-improvements
```

## Search Task History

If user provides partial name or keywords:

```bash
# Search in summaries
grep -r -l "$ARGUMENTS" .claude/state/completed/*/summary.md
```

## Export Task Summary

Offer to export for documentation:

```
Would you like to export this task summary?
1. Markdown file (for docs/)
2. Copy to clipboard
3. No export needed
```

## No History Case

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 TASK HISTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No completed tasks yet.

Start your first task with:
/new-task <task-name>
```
