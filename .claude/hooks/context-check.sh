#!/bin/bash
#
# Context Check Hook (UserPromptSubmit)
#
# Proactively monitors context usage and provides tiered warnings.
#
# CRITICAL: Auto-compact buffer is ~45k tokens (22.5% of 200k window)
# This means danger zone starts at 77.5% (155k tokens)
# We must act BEFORE this point!
#
# Warning Thresholds (adjusted for 45k buffer):
#   50% - Notice (good checkpoint opportunity)
#   60% - Warning (plan to save soon)
#   70% - Strong Warning (finish step, then save+clear)
#   75% - CRITICAL (save NOW - only 5k tokens to danger zone)
#
# Input: JSON with user prompt
# Output: JSON with warnings in systemMessage
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

# Helper to output JSON response with system message
output_json() {
    local context="$1"
    local escaped
    escaped=$(json_escape "$context")
    printf '{\n  "continue": true,\n  "suppressOutput": false,\n  "systemMessage": "%s"\n}\n' "$escaped"
}

# Helper to output simple continue (no warning)
output_continue() {
    echo '{"continue": true}'
}

# Helper to auto-save state
auto_save_state() {
    local project_dir="$1"
    local session_id="$2"
    local timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)

    # Update active.md with auto-save marker
    local state_file="$project_dir/.claude/state/active.md"
    if [ -f "$state_file" ]; then
        # Add auto-save note to session history if possible
        if grep -q "## Session History" "$state_file" 2>/dev/null; then
            # Append to session history
            sed -i "/## Session History/a | $timestamp | AUTO-SAVE | Context at critical level |" "$state_file" 2>/dev/null || true
        fi
    fi

    # Create emergency checkpoint file
    local checkpoint_dir="$project_dir/.claude/state/checkpoints"
    mkdir -p "$checkpoint_dir" 2>/dev/null || true

    local checkpoint_file="$checkpoint_dir/auto-save-$(date +%Y%m%d-%H%M%S).md"
    cat > "$checkpoint_file" 2>/dev/null << CHECKPOINT
# Auto-Save Checkpoint

Created: $timestamp
Session: $session_id
Reason: Context reached 75%+ (approaching auto-compact buffer)

## Action Required

Run these commands NOW:
1. /save-state (if you need to save more details)
2. /clear

Your state will auto-reload on the fresh session.

## Current State Snapshot

$(cat "$state_file" 2>/dev/null || echo "State file not available")
CHECKPOINT

    echo "$checkpoint_file"
}

# Read input from stdin (required even if not used)
INPUT=$(cat)

# Get session ID for per-session tracking
# --- SSM v3 session identity (see session-start.sh for rationale) ----------
SESSION_ID="${CLAUDE_SESSION_ID:-}"
if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")
fi
[ -z "$SESSION_ID" ] && SESSION_ID="default"
# --------------------------------------------------------------------------
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# --- SSM v3 heartbeat: UserPromptSubmit fires on every prompt, so this is the
# most reliable liveness signal for multi-session conflict detection.
SSM_LOCKS_DIR="$PROJECT_DIR/.claude/state/locks"
mkdir -p "$SSM_LOCKS_DIR" 2>/dev/null || true
date -Iseconds > "$SSM_LOCKS_DIR/$SESSION_ID.heartbeat" 2>/dev/null || true

# --- Phase C: flag a conflicting LIVE session on this session's Current Task.
# Runs every prompt (warn-once per conflict), independent of context level.
CONFLICT_WARNING=""
SESSION_STATE_F="$PROJECT_DIR/.claude/state/sessions/session-$SESSION_ID.md"
if [ -f "$SESSION_STATE_F" ]; then
    CUR_TASK=$(grep -A1 "^## Current Task" "$SESSION_STATE_F" 2>/dev/null | tail -1 | tr -d '[:space:]')
    if [ -n "$CUR_TASK" ] && [ "$CUR_TASK" != "none" ] && [ "$CUR_TASK" != "None" ]; then
        LOCK_F="$SSM_LOCKS_DIR/$CUR_TASK.lock"
        if [ -f "$LOCK_F" ]; then
            OWNER=$(head -1 "$LOCK_F" 2>/dev/null | tr -d '[:space:]')
            if [ -n "$OWNER" ] && [ "$OWNER" != "$SESSION_ID" ]; then
                OHB="$SSM_LOCKS_DIR/$OWNER.heartbeat"
                if [ -f "$OHB" ]; then
                    OLAST=$(date -d "$(cat "$OHB" 2>/dev/null)" +%s 2>/dev/null || echo 0)
                    OAGE=$(( ( $(date +%s) - OLAST ) / 60 ))
                    if [ "$OAGE" -lt 30 ]; then
                        CWARN_FILE="/tmp/ssm-warned-$SESSION_ID.txt"
                        CTOKEN="active-conflict:$CUR_TASK:$OWNER"
                        if ! grep -qxF "$CTOKEN" "$CWARN_FILE" 2>/dev/null; then
                            echo "$CTOKEN" >> "$CWARN_FILE" 2>/dev/null || true
                            CONFLICT_WARNING="⚠️ SSM CONFLICT: your Current Task '$CUR_TASK' is also held by another LIVE session ($OWNER, active ${OAGE}m ago). Two sessions on one task can clobber each other's state. Coordinate, or have one session /release-task."
                        fi
                    fi
                fi
            fi
        fi
    fi
fi

# Multiple ways to get context percentage
CONTEXT_PCT=0

# Method 1: Check session-specific temp file (written by status.sh)
CONTEXT_FILE="/tmp/claude-context-pct-$SESSION_ID.txt"
if [ -f "$CONTEXT_FILE" ]; then
    RAW_PCT=$(cat "$CONTEXT_FILE" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")
    if [ -n "$RAW_PCT" ] && [ "$RAW_PCT" -eq "$RAW_PCT" ] 2>/dev/null; then
        CONTEXT_PCT="$RAW_PCT"
    fi
fi

# Method 2: Check global temp file as fallback
if [ "$CONTEXT_PCT" -eq 0 ]; then
    GLOBAL_CONTEXT_FILE="/tmp/claude-context-pct.txt"
    if [ -f "$GLOBAL_CONTEXT_FILE" ]; then
        RAW_PCT=$(cat "$GLOBAL_CONTEXT_FILE" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")
        if [ -n "$RAW_PCT" ] && [ "$RAW_PCT" -eq "$RAW_PCT" ] 2>/dev/null; then
            CONTEXT_PCT="$RAW_PCT"
        fi
    fi
fi

# If we can't determine context, still surface a conflict warning if present
if [ "$CONTEXT_PCT" -eq 0 ] 2>/dev/null; then
    if [ -n "$CONFLICT_WARNING" ]; then
        output_json "$CONFLICT_WARNING"
    else
        output_continue
    fi
    exit 0
fi

# Track warning state to avoid duplicate warnings
WARNING_STATE_FILE="/tmp/claude-last-warning-$SESSION_ID.txt"
LAST_WARNING_LEVEL=$(cat "$WARNING_STATE_FILE" 2>/dev/null || echo "0")

# Determine warning level and message
# CRITICAL: Buffer zone starts at 77.5%, so 75% is our last safe checkpoint
WARNING=""
CURRENT_WARNING_LEVEL=0

if [ "$CONTEXT_PCT" -ge 75 ]; then
    # CRITICAL - Only ~5k tokens before danger zone!
    CURRENT_WARNING_LEVEL=75

    if [ "$LAST_WARNING_LEVEL" -lt 75 ]; then
        # Auto-save state
        CHECKPOINT_FILE=$(auto_save_state "$PROJECT_DIR" "$SESSION_ID" 2>/dev/null || echo "")

        CHECKPOINT_MSG=""
        if [ -n "$CHECKPOINT_FILE" ] && [ -f "$CHECKPOINT_FILE" ]; then
            CHECKPOINT_MSG="Auto-checkpoint saved: $CHECKPOINT_FILE"
        fi

        WARNING="🚨 CONTEXT CRITICAL: ${CONTEXT_PCT}% - SAVE NOW!

You are ~5k tokens from the auto-compact danger zone (77.5%).
Auto-compaction WILL be blocked, but you must clear context NOW.

$CHECKPOINT_MSG

ACTION REQUIRED:
  1. /save-state    ← Run immediately
  2. /clear         ← Then run this

Your state will auto-reload. This is NORMAL for large tasks.
Continuing without clearing risks context degradation."
    fi

elif [ "$CONTEXT_PCT" -ge 70 ]; then
    # STRONG WARNING - Getting close
    CURRENT_WARNING_LEVEL=70

    if [ "$LAST_WARNING_LEVEL" -lt 70 ]; then
        WARNING="⚠️ CONTEXT HIGH: ${CONTEXT_PCT}%

Finish your current step, then save and clear.
Danger zone starts at 77.5% (~15k tokens away).

RECOMMENDED:
  1. Complete current step
  2. /save-state
  3. /clear

Large tasks naturally span multiple sessions - this is expected!"
    fi

elif [ "$CONTEXT_PCT" -ge 60 ]; then
    # WARNING - Plan ahead
    CURRENT_WARNING_LEVEL=60

    if [ "$LAST_WARNING_LEVEL" -lt 60 ]; then
        WARNING="📊 CONTEXT NOTICE: ${CONTEXT_PCT}%

Plan to save state soon. You have room for ~1-2 more steps.

When you reach a good stopping point:
  /save-state → /clear

Tip: Check your task's plan.md for recommended checkpoint phases."
    fi

elif [ "$CONTEXT_PCT" -ge 50 ]; then
    # NOTICE - Good checkpoint opportunity
    CURRENT_WARNING_LEVEL=50

    if [ "$LAST_WARNING_LEVEL" -lt 50 ]; then
        WARNING="💡 CONTEXT: ${CONTEXT_PCT}%

Good checkpoint opportunity if you're at a natural break point.
No action required yet - just awareness."
    fi
fi

# Update warning state
if [ "$CURRENT_WARNING_LEVEL" -gt 0 ]; then
    echo "$CURRENT_WARNING_LEVEL" > "$WARNING_STATE_FILE" 2>/dev/null || true
fi

# Reset warning state if context dropped significantly (user cleared)
if [ "$CONTEXT_PCT" -lt 40 ] && [ "$LAST_WARNING_LEVEL" -gt 0 ]; then
    rm -f "$WARNING_STATE_FILE" 2>/dev/null || true
fi

# Prepend any conflict warning so it rides alongside the context warning
if [ -n "$CONFLICT_WARNING" ]; then
    if [ -n "$WARNING" ]; then
        WARNING="$CONFLICT_WARNING

$WARNING"
    else
        WARNING="$CONFLICT_WARNING"
    fi
fi

# Output response
if [ -n "$WARNING" ]; then
    output_json "$WARNING"
else
    output_continue
fi
