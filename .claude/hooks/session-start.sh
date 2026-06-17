#!/bin/bash
#
# Session Start Hook - Multi-Instance Aware
# Loads session-specific state and syncs progress to TodoWrite
#
# Input: JSON with source field
# Output: JSON with systemMessage to inject
#

# DO NOT use set -e - hooks must always return valid JSON

# Helper function to escape string for JSON
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    printf '%s' "$str"
}

# Helper to output JSON response
output_json() {
    local context="$1"
    local escaped
    escaped=$(json_escape "$context")
    printf '{\n  "continue": true,\n  "suppressOutput": false,\n  "systemMessage": "%s"\n}\n' "$escaped"
}

# Helper to output simple continue
output_continue() {
    echo '{"continue": true}'
}

# Read input from stdin
INPUT=$(cat)

# Get the session source
SOURCE=$(echo "$INPUT" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "unknown")

# Get project directory and session ID
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# --- SSM v3 session identity --------------------------------------------
# Prefer the stable session id. The env var and the hook JSON `session_id`
# are the same value for the life of the session, so commands (which see the
# env var) and hooks (which see the JSON) stay aligned. Fall back to the JSON
# payload, then to "default".
# The old $PPID fallback was REMOVED: PPID collides across terminals, which
# made two sessions share one state file and silently corrupt task state.
SESSION_ID="${CLAUDE_SESSION_ID:-}"
if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")
fi
[ -z "$SESSION_ID" ] && SESSION_ID="default"
# ------------------------------------------------------------------------

SESSION_DIR="$PROJECT_DIR/.claude/state/sessions"
SESSION_STATE="$SESSION_DIR/session-$SESSION_ID.md"
ACTIVE_STATE="$PROJECT_DIR/.claude/state/active.md"
ACTIVE_TASKS="$PROJECT_DIR/.claude/state/active-tasks.md"

# Ensure session directory exists
mkdir -p "$SESSION_DIR" 2>/dev/null || true

# --- SSM v3 heartbeat: record this session's liveness for conflict detection.
# Other sessions read these to tell a live session from a crashed one.
LOCKS_DIR="$PROJECT_DIR/.claude/state/locks"
mkdir -p "$LOCKS_DIR" 2>/dev/null || true
date -Iseconds > "$LOCKS_DIR/$SESSION_ID.heartbeat" 2>/dev/null || true

# Reset the Phase-C nudge debounce so a fresh session re-flags any wrong-task
# or conflict situation (rather than staying silent after a prior warning).
rm -f "/tmp/ssm-warned-$SESSION_ID.txt" 2>/dev/null || true

# Determine which state file to use
STATE_FILE=""
STATE_TYPE=""

if [ -f "$SESSION_STATE" ]; then
    STATE_FILE="$SESSION_STATE"
    STATE_TYPE="session: $SESSION_ID"
elif [ -f "$ACTIVE_STATE" ]; then
    STATE_FILE="$ACTIVE_STATE"
    STATE_TYPE="single-instance mode"
fi

# If no state file exists, show new session message
if [ -z "$STATE_FILE" ]; then
    CONTEXT="📋 NEW SESSION (session: $SESSION_ID)

No active task. Start with:
  /new-task <name> - Create a new task
  /active-tasks    - See all tasks
  /claim-task <id> - Take over a paused task

Context thresholds (IMPORTANT):
  < 70%  - Safe to work
  70-75% - Save soon
  > 75%  - SAVE NOW (danger at 77.5%)"

    output_json "$CONTEXT"
    exit 0
fi

# Extract key information from state file
CURRENT_TASK=$(grep -A1 "^## Current Task" "$STATE_FILE" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo "none")
[ -z "$CURRENT_TASK" ] && CURRENT_TASK="none"

PHASE=$(grep "^PHASE:" "$STATE_FILE" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "unknown")
[ -z "$PHASE" ] && PHASE="unknown"

CURRENT_FOCUS=$(grep -A1 "^## Current Focus" "$STATE_FILE" 2>/dev/null | tail -1 || echo "No focus set")
[ -z "$CURRENT_FOCUS" ] && CURRENT_FOCUS="No focus set"

LAST_ACTION=$(grep "^LAST_ACTION:" "$STATE_FILE" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "No previous action")
[ -z "$LAST_ACTION" ] && LAST_ACTION="No previous action"

# Extract immediate context files (first 5 only)
CONTEXT_FILES=$(grep -A10 "^## Immediate Context" "$STATE_FILE" 2>/dev/null | grep "^- " | head -5 | sed 's/^- /  - /' || echo "  - No files listed")
[ -z "$CONTEXT_FILES" ] && CONTEXT_FILES="  - No files listed"

# Extract next steps (first 3 only)
NEXT_STEPS=$(grep -A5 "^## Next Steps" "$STATE_FILE" 2>/dev/null | grep -E "^[0-9]|^\[" | head -3 || echo "No next steps defined")
[ -z "$NEXT_STEPS" ] && NEXT_STEPS="No next steps defined"

# Check for blockers
BLOCKED=$(grep "^BLOCKED:" "$STATE_FILE" 2>/dev/null | cut -d':' -f2 | tr -d '[:space:]' || echo "No")
BLOCKERS=""
if [ "$BLOCKED" = "Yes" ]; then
    BLOCKERS=$(grep -A5 "^## Blockers" "$STATE_FILE" 2>/dev/null | grep "^- " | head -3 || true)
fi

# Get progress from progress.md if task exists
PROGRESS_INFO=""
PROGRESS_SYNC_NOTE=""
if [ "$CURRENT_TASK" != "none" ] && [ -f "$PROJECT_DIR/tasks/$CURRENT_TASK/progress.md" ]; then
    PROGRESS_FILE="$PROJECT_DIR/tasks/$CURRENT_TASK/progress.md"
    TOTAL=$(grep -c '^\- \[' "$PROGRESS_FILE" 2>/dev/null || echo 0)
    DONE=$(grep -c '^\- \[x\]' "$PROGRESS_FILE" 2>/dev/null || echo 0)

    if [ "$TOTAL" -gt 0 ]; then
        PERCENT=$((DONE * 100 / TOTAL))
        PROGRESS_INFO="Progress: $DONE/$TOTAL steps ($PERCENT%)"
        PROGRESS_SYNC_NOTE="

NOTE: Sync progress.md to TodoWrite with /task-status"
    fi
fi

# Extract the Design Contract from plan.md (the durable "HOW"). This is the
# Phase-B fix for strategy loss across sessions: re-inject the binding design
# on every resume so the agent doesn't drift off-architecture. Bounded to keep
# it small — it is meant to be ≤ ~25 lines by construction.
DESIGN_CONTRACT=""
if [ "$CURRENT_TASK" != "none" ] && [ -f "$PROJECT_DIR/tasks/$CURRENT_TASK/plan.md" ]; then
    DESIGN_CONTRACT=$(awk '/^## Design Contract/{f=1;next} /^## /{f=0} f' \
        "$PROJECT_DIR/tasks/$CURRENT_TASK/plan.md" 2>/dev/null \
        | grep -v '^<!--' | grep -v '^-->' | grep -v '^[[:space:]]*$' | head -30 || echo "")
fi

# Check for other active tasks across sessions
OTHER_TASKS=""
if [ -f "$ACTIVE_TASKS" ]; then
    OTHER_COUNT=$(grep -c "IN_PROGRESS" "$ACTIVE_TASKS" 2>/dev/null || echo 0)
    if [ "$OTHER_COUNT" -gt 1 ]; then
        OTHER_TASKS="

Other active tasks: $((OTHER_COUNT - 1)) (use /active-tasks to see all)"
    elif [ "$OTHER_COUNT" -eq 1 ] && [ "$CURRENT_TASK" = "none" ]; then
        OTHER_TASKS="

1 active task exists (use /active-tasks to see)"
    fi
fi

# Build the context message
CONTEXT="SESSION STATE LOADED ($STATE_TYPE)

Task: $CURRENT_TASK
Phase: $PHASE
$PROGRESS_INFO

Current Focus:
$CURRENT_FOCUS

Files to Load:
$CONTEXT_FILES

Next Steps:
$NEXT_STEPS"

# Inject the Design Contract (binding implementation strategy) if present
if [ -n "$DESIGN_CONTRACT" ]; then
    CONTEXT="$CONTEXT

━━━ DESIGN CONTRACT (binding — implement to THIS) ━━━
$DESIGN_CONTRACT

⚠️ Honor the Design Contract above. Before writing code, read
   tasks/$CURRENT_TASK/plan.md and tasks/$CURRENT_TASK/decisions.md in full."
fi

# Add blocker warning if present
if [ -n "$BLOCKERS" ]; then
    CONTEXT="$CONTEXT

⚠️ BLOCKERS:
$BLOCKERS"
fi

# Add other tasks info
if [ -n "$OTHER_TASKS" ]; then
    CONTEXT="$CONTEXT
$OTHER_TASKS"
fi

# Add progress sync note
if [ -n "$PROGRESS_SYNC_NOTE" ]; then
    CONTEXT="$CONTEXT
$PROGRESS_SYNC_NOTE"
fi

# Add context warning reminder
CONTEXT="$CONTEXT

Context Limits: 70% warning | 75% CRITICAL | 77.5% danger
Commands: /task-status | /save-state | /active-tasks"

output_json "$CONTEXT"
