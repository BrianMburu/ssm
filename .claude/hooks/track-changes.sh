#!/bin/bash
#
# Track Changes Hook (PreToolUse: Edit|Write)
# Records which files are being modified during the session
# This helps /save-state know what was worked on
#
# Input: JSON with tool_name, tool_input fields
# Output: JSON with continue: true
#

# DO NOT use set -e - hooks must always return valid JSON

# Helper: escape a string for embedding in JSON
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"; str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"; str="${str//$'\t'/\\t}"
    printf '%s' "$str"
}

# Read input from stdin
INPUT=$(cat)

# Extract file path from tool input
# Edit tool uses "file_path", Write tool uses "file_path"  
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 | head -1 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
    # Try alternate field names
    FILE_PATH=$(echo "$INPUT" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 | head -1 2>/dev/null || echo "")
fi

# Get project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# --- SSM v3 session identity (see session-start.sh for rationale) ----------
SESSION_ID="${CLAUDE_SESSION_ID:-}"
if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")
fi
[ -z "$SESSION_ID" ] && SESSION_ID="default"
# --------------------------------------------------------------------------

TRACKING_FILE="/tmp/ssm-modified-files-$SESSION_ID.txt"
# Tasks inferred from edited paths this session (feeds the save-state
# reconciliation guard that prevents writing progress to the wrong task).
TASK_HINT_FILE="/tmp/ssm-session-tasks-$SESSION_ID.txt"

# Track the file if we found a path
if [ -n "$FILE_PATH" ]; then
    # Normalize the path (remove project dir prefix if present)
    RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"
    
    # Add to tracking file (avoid duplicates)
    if [ -f "$TRACKING_FILE" ]; then
        # Use grep with || true to prevent exit on no match
        if ! grep -qF "$RELATIVE_PATH" "$TRACKING_FILE" 2>/dev/null; then
            echo "$RELATIVE_PATH" >> "$TRACKING_FILE" 2>/dev/null || true
        fi
    else
        echo "$RELATIVE_PATH" > "$TRACKING_FILE" 2>/dev/null || true
    fi

    # Infer task id when editing files under tasks/<id>/ — a strong signal of
    # which task is actually being worked on. Recorded most-recent-last so the
    # reconciliation guard can compare it against the session's "Current Task".
    case "$RELATIVE_PATH" in
        tasks/*/*)
            TASK_HINT=$(printf '%s' "$RELATIVE_PATH" | cut -d'/' -f2)
            [ -n "$TASK_HINT" ] && echo "$TASK_HINT" >> "$TASK_HINT_FILE" 2>/dev/null || true
            ;;
    esac
fi

# --- Phase C: proactive in-session nudge (warn, never block) ---------------
# When the EDITED task (inferred from a tasks/<id>/ path) differs from the
# session's Current Task, or is locked by another LIVE session, surface a
# warning so the agent can ask the user — preventing wrong-task saves and
# concurrent clobbering at the moment they start, not just at save time.
# NOTE: only fires for edits under tasks/<id>/; source-file edits carry no task
# id, so the /save-state reconciliation guard remains the backstop.
WARNING=""
if [ -n "${TASK_HINT:-}" ]; then
    SESSION_STATE="$PROJECT_DIR/.claude/state/sessions/session-$SESSION_ID.md"
    LOCKS_DIR="$PROJECT_DIR/.claude/state/locks"
    WARNED_FILE="/tmp/ssm-warned-$SESSION_ID.txt"

    CURRENT_TASK=""
    [ -f "$SESSION_STATE" ] && CURRENT_TASK=$(grep -A1 "^## Current Task" "$SESSION_STATE" 2>/dev/null | tail -1 | tr -d '[:space:]')

    # 1) Wrong-task edit: editing a different task than the session thinks is current
    if [ -n "$CURRENT_TASK" ] && [ "$CURRENT_TASK" != "none" ] && [ "$CURRENT_TASK" != "None" ] && [ "$TASK_HINT" != "$CURRENT_TASK" ]; then
        TOKEN="mismatch:$TASK_HINT:$CURRENT_TASK"
        if ! grep -qxF "$TOKEN" "$WARNED_FILE" 2>/dev/null; then
            echo "$TOKEN" >> "$WARNED_FILE" 2>/dev/null || true
            WARNING="⚠️ SSM: You're editing files under tasks/$TASK_HINT/ but the session's Current Task is '$CURRENT_TASK'. Saving now would record progress against '$CURRENT_TASK'. Confirm with the user, then switch with /claim-task $TASK_HINT (or keep '$CURRENT_TASK')."
        fi
    fi

    # 2) Foreign live lock: the edited task is owned by another active session
    LOCK="$LOCKS_DIR/$TASK_HINT.lock"
    if [ -f "$LOCK" ]; then
        LOCK_OWNER=$(head -1 "$LOCK" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$LOCK_OWNER" ] && [ "$LOCK_OWNER" != "$SESSION_ID" ]; then
            HB="$LOCKS_DIR/$LOCK_OWNER.heartbeat"
            if [ -f "$HB" ]; then
                LAST=$(date -d "$(cat "$HB" 2>/dev/null)" +%s 2>/dev/null || echo 0)
                AGE_MIN=$(( ( $(date +%s) - LAST ) / 60 ))
                if [ "$AGE_MIN" -lt 30 ]; then
                    TOKEN="conflict:$TASK_HINT:$LOCK_OWNER"
                    if ! grep -qxF "$TOKEN" "$WARNED_FILE" 2>/dev/null; then
                        echo "$TOKEN" >> "$WARNED_FILE" 2>/dev/null || true
                        WARNING="${WARNING:+$WARNING }⚠️ SSM: task '$TASK_HINT' is locked by another LIVE session ($LOCK_OWNER, active ${AGE_MIN}m ago). Editing it risks conflicting updates — confirm with the user before continuing."
                    fi
                fi
            fi
        fi
    fi
fi

# Emit the nudge as context for Claude without blocking the edit.
if [ -n "$WARNING" ]; then
    printf '{"continue": true, "systemMessage": "%s", "hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "%s"}}\n' \
        "$(json_escape "$WARNING")" "$(json_escape "$WARNING")"
else
    echo '{"continue": true}'
fi
