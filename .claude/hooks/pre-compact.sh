#!/bin/bash
#
# Pre-Compact Hook - BLOCKS ALL COMPACTION
#
# SSM philosophy: Compaction degrades context quality. Always use save-state + clear instead.
#
# - Manual compact: BLOCK with guidance to use /save-state + /clear
# - Auto compact: BLOCK with urgent guidance (creates emergency handoff first)
#
# Input: JSON with trigger field (auto|manual)
# Output: JSON with continue: false to block compaction
#

# DO NOT use set -e - hooks must always return valid JSON

# Read input from stdin
INPUT=$(cat)

# Get the trigger type
TRIGGER=$(echo "$INPUT" | grep -o '"trigger"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "unknown")

# Get project directory and timestamp
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
ACTIVE_STATE="$PROJECT_DIR/.claude/state/active.md"
TIMESTAMP=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Helper: Create emergency handoff file
create_emergency_handoff() {
    local task="$1"
    local handoff_dir="$PROJECT_DIR/tasks/$task/handoffs"
    local handoff_file="$handoff_dir/emergency-$(date +%Y%m%d-%H%M%S 2>/dev/null || echo 'unknown').md"

    mkdir -p "$handoff_dir" 2>/dev/null || return 1

    cat > "$handoff_file" 2>/dev/null << HANDOFF
# Emergency Handoff (Compaction Blocked)

Created: $TIMESTAMP
Session: $SESSION_ID
Trigger: Context limit reached (~95%)

## Important

Compaction was BLOCKED to preserve context quality.
Please run /save-state then /clear to continue.

## Current State Snapshot

Task: $task

### State at Block
$(cat "$ACTIVE_STATE" 2>/dev/null || echo "State file not found")

---

## Recovery Steps

1. Run /save-state to save your current progress
2. Run /clear to start fresh
3. Your state will auto-load on the new session
4. Continue from where you left off

This approach preserves full context fidelity.
HANDOFF

    echo "$handoff_file"
}

# Get current task info
CURRENT_TASK="unknown"
if [ -f "$ACTIVE_STATE" ]; then
    CURRENT_TASK=$(grep -A1 "^## Current Task" "$ACTIVE_STATE" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo "unknown")
fi
[ -z "$CURRENT_TASK" ] && CURRENT_TASK="unknown"

if [ "$TRIGGER" = "manual" ]; then
    # BLOCK manual compaction
    cat << 'EOF'
{
  "continue": false,
  "stopReason": "COMPACTION BLOCKED\n\nCompaction degrades context quality through summarization.\nUse SSM's state management workflow instead:\n\n  1. Run /save-state to preserve your progress\n  2. Run /clear to start fresh\n  3. State auto-loads on new session\n\nThis maintains full context fidelity vs lossy compaction."
}
EOF

elif [ "$TRIGGER" = "auto" ]; then
    # BLOCK auto-compaction (with emergency handoff)

    # Create emergency handoff first
    HANDOFF_FILE=$(create_emergency_handoff "$CURRENT_TASK" 2>/dev/null || echo "")

    if [ -n "$HANDOFF_FILE" ] && [ -f "$HANDOFF_FILE" ]; then
        HANDOFF_MSG="Emergency handoff saved to: $HANDOFF_FILE"
    else
        HANDOFF_MSG="(Could not create handoff file)"
    fi

    # BLOCK compaction - this is the key change
    cat << EOF
{
  "continue": false,
  "stopReason": "AUTO-COMPACTION BLOCKED\\n\\nContext window is nearly full, but compaction has been prevented.\\nCompaction degrades quality - use save+clear instead:\\n\\n  1. Run /save-state NOW\\n  2. Run /clear\\n  3. Continue with fresh context\\n\\n$HANDOFF_MSG"
}
EOF

else
    # Unknown trigger - block to be safe
    cat << 'EOF'
{
  "continue": false,
  "stopReason": "COMPACTION BLOCKED\n\nUse /save-state + /clear instead to preserve context quality."
}
EOF
fi
