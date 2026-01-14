#!/bin/bash
#
# Stop Hook - Intelligent Task Continuation
#
# Evaluates if there's incomplete work and suggests continuation.
# Helps prevent premature session endings when tasks are in progress.
#
# Input: JSON with session context
# Output: JSON with continue: true/false and optional reason
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

# Read input from stdin
INPUT=$(cat)

# Get project directory and session info
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
ACTIVE_STATE="$PROJECT_DIR/.claude/state/active.md"

# Default: allow stop
SHOULD_CONTINUE="false"
REASON=""

# Check if there's an active task with incomplete work
if [ -f "$ACTIVE_STATE" ]; then
    # Get current task
    CURRENT_TASK=$(grep -A1 "^## Current Task" "$ACTIVE_STATE" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo "")

    # Get blocked status
    BLOCKED=$(grep "^BLOCKED:" "$ACTIVE_STATE" 2>/dev/null | cut -d':' -f2 | tr -d '[:space:]' || echo "No")

    # Get phase info
    PHASE=$(grep "^PHASE:" "$ACTIVE_STATE" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")

    # Get current focus
    CURRENT_FOCUS=$(grep -A1 "^## Current Focus" "$ACTIVE_STATE" 2>/dev/null | tail -1 || echo "")

    # Check if there are pending next steps
    PENDING_STEPS=$(grep -A10 "^## Next Steps" "$ACTIVE_STATE" 2>/dev/null | grep -c "^\[[ ]\]" || echo "0")

    # Determine if we should suggest continuation
    if [ -n "$CURRENT_TASK" ] && [ "$CURRENT_TASK" != "none" ] && [ "$CURRENT_TASK" != "unknown" ]; then
        # Task is active
        if [ "$BLOCKED" = "Yes" ]; then
            # Task is blocked - allow stop but remind about blocker
            SHOULD_CONTINUE="false"
            # No reason needed - just allow stop
        elif [ "$PENDING_STEPS" -gt 0 ]; then
            # There are pending steps - suggest continuation
            SHOULD_CONTINUE="true"
            REASON="Task '$CURRENT_TASK' has $PENDING_STEPS pending steps.\\n\\nCurrent focus: $CURRENT_FOCUS\\n\\nWould you like to continue? If done for now, run /save-state first."
        fi
    fi
fi

# Output decision
if [ "$SHOULD_CONTINUE" = "true" ] && [ -n "$REASON" ]; then
    # Suggest continuation
    printf '{\n  "continue": true,\n  "reason": "%s"\n}\n' "$(json_escape "$REASON")"
else
    # Allow stop
    echo '{"continue": false}'
fi
