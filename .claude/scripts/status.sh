#!/bin/bash
#
# Status Line Script
# Shows: Context% | Branch Status | Task | Current Focus
#
# Output format:
# 🟢 45% | main U:3 | auth-refactor | Step 3/7: Writing tests
#

# DO NOT use set -e - status script must always output something

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
ACTIVE_STATE="$PROJECT_DIR/.claude/state/active.md"
SESSION_STATE="$PROJECT_DIR/.claude/state/sessions/session-$SESSION_ID.md"
CONTEXT_FILE="/tmp/claude-context-pct-$SESSION_ID.txt"

# Use session state if available, otherwise active.md
STATE_FILE="$ACTIVE_STATE"
if [ -f "$SESSION_STATE" ]; then
    STATE_FILE="$SESSION_STATE"
fi

# --- Context Percentage ---
CONTEXT_PCT="--"
if [ -f "$CONTEXT_FILE" ]; then
    CONTEXT_PCT=$(cat "$CONTEXT_FILE" 2>/dev/null || echo "--")
fi

# Color indicator based on percentage
COLOR_ICON="⚪"
if [ "$CONTEXT_PCT" != "--" ]; then
    PCT_NUM=$(echo "$CONTEXT_PCT" | grep -o '[0-9]*' | head -1 2>/dev/null || echo "0")
    if [ -n "$PCT_NUM" ] && [ "$PCT_NUM" -eq "$PCT_NUM" ] 2>/dev/null; then
        if [ "$PCT_NUM" -lt 60 ]; then
            COLOR_ICON="🟢"
        elif [ "$PCT_NUM" -lt 80 ]; then
            COLOR_ICON="🟡"
        else
            COLOR_ICON="🔴"
        fi
    fi
fi

# --- Git Status ---
GIT_STATUS=""
if [ -d "$PROJECT_DIR/.git" ]; then
    BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "?")
    
    # Count changes (with safe defaults)
    STAGED=$(git -C "$PROJECT_DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    UNSTAGED=$(git -C "$PROJECT_DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    UNTRACKED=$(git -C "$PROJECT_DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    
    CHANGES=""
    [ "$STAGED" -gt 0 ] 2>/dev/null && CHANGES="${CHANGES}S:$STAGED "
    [ "$UNSTAGED" -gt 0 ] 2>/dev/null && CHANGES="${CHANGES}U:$UNSTAGED "
    [ "$UNTRACKED" -gt 0 ] 2>/dev/null && CHANGES="${CHANGES}?:$UNTRACKED"
    
    GIT_STATUS="$BRANCH ${CHANGES}"
fi

# --- Current Task ---
TASK="none"
PHASE=""
if [ -f "$STATE_FILE" ]; then
    TASK=$(grep -A1 "^## Current Task" "$STATE_FILE" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo "none")
    PHASE=$(grep "^PHASE:" "$STATE_FILE" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' | head -c 30 || echo "")
    
    # Handle empty task
    [ -z "$TASK" ] && TASK="none"
fi

# --- Build Status Line ---
# Format: 🟢 45% | main U:3 | auth-refactor | Step 3/7
OUTPUT="$COLOR_ICON $CONTEXT_PCT"

[ -n "$GIT_STATUS" ] && OUTPUT="$OUTPUT | $GIT_STATUS"
[ "$TASK" != "none" ] && OUTPUT="$OUTPUT | $TASK"
[ -n "$PHASE" ] && OUTPUT="$OUTPUT | $PHASE"

echo "$OUTPUT"
