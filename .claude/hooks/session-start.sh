#!/bin/bash
#
# Session Start Hook - Multi-Instance Aware
# Loads session-specific state when session starts (startup|resume|clear|compact)
#
# Input: JSON with source field
# Output: JSON with additionalContext to inject
#

# DO NOT use set -e - hooks must always return valid JSON

# Helper function to escape string for JSON
json_escape() {
    local str="$1"
    # Escape backslashes first, then quotes, then convert newlines
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
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_DIR="$PROJECT_DIR/.claude/state/sessions"
SESSION_STATE="$SESSION_DIR/session-$SESSION_ID.md"
ACTIVE_STATE="$PROJECT_DIR/.claude/state/active.md"
ACTIVE_TASKS="$PROJECT_DIR/.claude/state/active-tasks.md"

# Ensure session directory exists (silently)
mkdir -p "$SESSION_DIR" 2>/dev/null || true

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

Ready to start! Use /new-task <name> to begin.

Commands:
- /new-task <name> - Start a new task
- /active-tasks - See all tasks
- /task-history - View completed tasks"
    
    output_json "$CONTEXT"
    exit 0
fi

# Extract key information from state file (with safe defaults)
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

# Build the context message
CONTEXT="SESSION STATE LOADED ($STATE_TYPE)

Current Task: $CURRENT_TASK
Phase: $PHASE
Last Action: $LAST_ACTION

Current Focus:
$CURRENT_FOCUS

Files to Load:
$CONTEXT_FILES

Next Steps:
$NEXT_STEPS"

# Add blocker warning if present
if [ -n "$BLOCKERS" ]; then
    CONTEXT="$CONTEXT

BLOCKERS DETECTED:
$BLOCKERS"
fi

CONTEXT="$CONTEXT

Commands: /continue-task | /task-status | /active-tasks"

output_json "$CONTEXT"
