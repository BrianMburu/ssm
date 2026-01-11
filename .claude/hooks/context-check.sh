#!/bin/bash
#
# Context Check Hook (UserPromptSubmit)
# Monitors context usage and provides tiered warnings
#
# Input: JSON with user prompt
# Output: JSON with optional warnings in additionalContext
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

# Read input from stdin (required even if not used)
INPUT=$(cat)

# Get session ID for per-session tracking
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
CONTEXT_FILE="/tmp/claude-context-pct-$SESSION_ID.txt"

# Read current context percentage
CONTEXT_PCT=0
if [ -f "$CONTEXT_FILE" ]; then
    # Extract just the number, default to 0 if not valid
    RAW_PCT=$(cat "$CONTEXT_FILE" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")
    if [ -n "$RAW_PCT" ] && [ "$RAW_PCT" -eq "$RAW_PCT" ] 2>/dev/null; then
        CONTEXT_PCT="$RAW_PCT"
    fi
fi

# If no tracking or 0%, just continue without warning
if [ "$CONTEXT_PCT" -eq 0 ] 2>/dev/null; then
    output_continue
    exit 0
fi

# Determine warning level
WARNING=""

if [ "$CONTEXT_PCT" -ge 90 ]; then
    WARNING="CONTEXT CRITICAL: ${CONTEXT_PCT}%

AUTO-COMPACTION IMMINENT!

Run these commands NOW to preserve your work:
  1. /save-state
  2. /clear

This will save your progress and start fresh with full context quality."

elif [ "$CONTEXT_PCT" -ge 80 ]; then
    WARNING="CONTEXT HIGH: ${CONTEXT_PCT}%

Recommended: Finish current task step, then:
  1. /save-state
  2. /clear

This prevents auto-compaction from losing context."

elif [ "$CONTEXT_PCT" -ge 70 ]; then
    WARNING="CONTEXT NOTICE: ${CONTEXT_PCT}%

Consider saving state when you reach a good stopping point."
fi

# Output response
if [ -n "$WARNING" ]; then
    output_json "$WARNING"
else
    output_continue
fi
