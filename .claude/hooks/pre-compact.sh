#!/bin/bash
#
# Pre-Compact Hook
# - Manual compact: BLOCK and prompt user to use /save-state + /clear
# - Auto compact: Create auto-save handoff before allowing
#
# Input: JSON with trigger field (auto|manual)
# Output: JSON with decision (block) or continue
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

if [ "$TRIGGER" = "manual" ]; then
    # BLOCK manual compaction
    cat << 'EOF'
{
  "decision": "block",
  "reason": "MANUAL COMPACTION BLOCKED\n\nCompaction degrades context quality. Use the state management workflow instead:\n\n1. Run /save-state to preserve current progress\n2. Run /clear to start fresh with full context quality\n3. Your state will auto-load on the new session\n\nThis approach maintains higher signal quality than compaction."
}
EOF

elif [ "$TRIGGER" = "auto" ]; then
    # Auto-compact triggered - create emergency handoff
    
    # Get current task info (with safe default)
    CURRENT_TASK="unknown"
    if [ -f "$ACTIVE_STATE" ]; then
        CURRENT_TASK=$(grep -A1 "^## Current Task" "$ACTIVE_STATE" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo "unknown")
    fi
    [ -z "$CURRENT_TASK" ] && CURRENT_TASK="unknown"
    
    # Create auto-handoff directory
    HANDOFF_DIR="$PROJECT_DIR/tasks/$CURRENT_TASK/handoffs"
    mkdir -p "$HANDOFF_DIR" 2>/dev/null || true
    
    # Create auto-handoff file
    HANDOFF_FILE="$HANDOFF_DIR/auto-handoff-$(date +%Y%m%d-%H%M%S 2>/dev/null || echo 'unknown').md"
    
    # Write handoff file (in subshell to avoid breaking on failure)
    (
    cat > "$HANDOFF_FILE" << HANDOFF
# Auto-Handoff (Context Limit Reached)

Created: $TIMESTAMP
Session: $SESSION_ID
Trigger: Auto-compaction (context window ~95% full)

## Warning

This handoff was created automatically because context reached capacity.
Some details may be missing. Review and supplement if needed.

## State at Compaction

Task: $CURRENT_TASK

### Last Known State
$(cat "$ACTIVE_STATE" 2>/dev/null || echo "State file not found")

---

## Recovery Instructions

1. After compaction, run /continue-task to reload state
2. Check tasks/$CURRENT_TASK/progress.md for task status
3. Review this handoff for any additional context

## Note

Consider running /save-state + /clear more frequently
to avoid auto-compaction. This preserves higher context quality.
HANDOFF
    ) 2>/dev/null || true

    # Allow compaction to proceed with message
    printf '{\n  "continue": true,\n  "suppressOutput": false,\n  "systemMessage": "AUTO-COMPACTION IN PROGRESS\\n\\nAn auto-handoff has been saved.\\nAfter compaction completes, your state will be reloaded.\\nConsider using /save-state + /clear more frequently."\n}\n'

else
    # Unknown trigger, allow by default
    echo '{"continue": true}'
fi
