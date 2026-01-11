# State Management Rules

These rules govern how session state is handled.

## Core Principles

### 1. Clear Over Compact

**Never** allow auto-compaction to degrade context. The workflow is:
1. Monitor context usage (status line shows percentage)
2. At ~70%, consider saving state
3. At ~80%, strongly recommend save + clear
4. At ~90%, urgently save + clear

**Why**: Compaction creates summaries of summaries, losing critical details. Fresh context + state file = full fidelity.

### 2. Explicit State Over Conversation Memory

**Always** write important information to state files, not just mention it in chat.

- Task progress → `tasks/<id>/progress.md`
- Decisions → `tasks/<id>/decisions.md`
- Current focus → `.claude/state/active.md`

**Why**: Conversation history is volatile and gets compacted. State files persist.

### 3. Single Source of Truth

`.claude/state/active.md` is THE source of truth for:
- What task is active
- What phase/step we're on
- What files are relevant
- What to work on next

**Why**: Prevents confusion from stale information in conversation history.

## Required Actions

### On Session Start
- Read `.claude/state/active.md`
- Load files from "Immediate Context"
- Continue from "Current Focus"

### Before /clear
- Run `/save-state` workflow
- Update active.md with current progress
- Update task progress.md
- Optionally commit state files

### On Task Completion
- Update progress.md checkboxes
- Add to session history
- Clear or update current focus
- Consider archiving task to completed/

## Prohibited Actions

### Never Do
- Ignore state files and rely on memory
- Continue work without checking active.md
- Clear without saving state first
- Let auto-compact run without intervention
- Store important decisions only in chat

### Avoid
- Loading files not in "Immediate Context"
- Loading files marked "Do NOT Load"
- Keeping irrelevant context loaded
- Working on multiple tasks in one session

## State File Standards

### Timestamps
Always use ISO 8601 format: `2026-01-10T14:30:00Z`

### Task Status Values
- `NOT_STARTED` - Task created but not begun
- `IN_PROGRESS` - Actively working
- `BLOCKED` - Cannot proceed (document blocker)
- `PAUSED` - Intentionally stopped
- `COMPLETED` - All items done
- `ARCHIVED` - Moved to completed/

### Checkbox Format
- `[ ]` - Not started
- `[ ] **NEXT** →` - Immediate next item
- `[ ] **IN PROGRESS** →` - Currently working on
- `[x]` - Completed
- `[-]` - Skipped/not applicable
