#!/bin/bash
#
# PostToolUse Hook - Auto-Save State After File Operations
#
# Automatically updates the Working Files section of active.md after
# successful Edit/Write operations. Includes smart debouncing to avoid
# excessive updates.
#
# Input: JSON with tool_name, tool_input, tool_response
# Output: JSON with continue: true and optional systemMessage
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

# Get environment
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
TIMESTAMP=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)

# State files
ACTIVE_STATE="$PROJECT_DIR/.claude/state/active.md"
SESSION_STATE="$PROJECT_DIR/.claude/state/sessions/session-$SESSION_ID.md"

# Debounce tracking
DEBOUNCE_FILE="/tmp/claude-autosave-$SESSION_ID.txt"
DEBOUNCE_SECONDS=30

# Extract tool info from input
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")

# Only process Edit and Write operations
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
    echo '{"continue": true}'
    exit 0
fi

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
    echo '{"continue": true}'
    exit 0
fi

# Skip SSM state files to avoid recursive updates
case "$FILE_PATH" in
    */.claude/state/*)
        echo '{"continue": true}'
        exit 0
        ;;
esac

# Check debounce - don't update more than once per 30 seconds
LAST_SAVE=0
if [ -f "$DEBOUNCE_FILE" ]; then
    LAST_SAVE=$(cat "$DEBOUNCE_FILE" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")
fi
CURRENT_TIME=$(date +%s 2>/dev/null || echo "0")
TIME_DIFF=$((CURRENT_TIME - LAST_SAVE))

# If within debounce window, just track the file silently
WORKING_FILES_CACHE="/tmp/claude-working-files-$SESSION_ID.txt"

# Always add file to cache (will be written on next non-debounced save)
echo "$FILE_PATH" >> "$WORKING_FILES_CACHE" 2>/dev/null || true

# If within debounce period, skip the state file update
if [ "$TIME_DIFF" -lt "$DEBOUNCE_SECONDS" ] 2>/dev/null; then
    echo '{"continue": true}'
    exit 0
fi

# Update debounce timestamp
echo "$CURRENT_TIME" > "$DEBOUNCE_FILE" 2>/dev/null || true

# Determine which state file to update
STATE_FILE=""
if [ -f "$SESSION_STATE" ]; then
    STATE_FILE="$SESSION_STATE"
elif [ -f "$ACTIVE_STATE" ]; then
    STATE_FILE="$ACTIVE_STATE"
fi

# If no state file exists, just continue
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
    echo '{"continue": true}'
    exit 0
fi

# Get unique files from cache
UNIQUE_FILES=""
if [ -f "$WORKING_FILES_CACHE" ]; then
    UNIQUE_FILES=$(sort -u "$WORKING_FILES_CACHE" 2>/dev/null | head -20)
    # Clear cache after reading
    : > "$WORKING_FILES_CACHE" 2>/dev/null || true
fi

# Build new Working Files section content
NEW_WORKING_FILES=""
while IFS= read -r file; do
    [ -n "$file" ] && NEW_WORKING_FILES="$NEW_WORKING_FILES- $file
"
done <<< "$UNIQUE_FILES"

# If no files to add, just continue
if [ -z "$NEW_WORKING_FILES" ]; then
    echo '{"continue": true}'
    exit 0
fi

# Update the Working Files section in state file
# This is a careful in-place update that preserves the rest of the file

# Create temp file for atomic update
TEMP_FILE=$(mktemp 2>/dev/null || echo "/tmp/ssm-state-update-$$")

# Process state file
{
    IN_WORKING_FILES=false
    WORKING_FILES_WRITTEN=false

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" == "## Working Files"* ]]; then
            IN_WORKING_FILES=true
            echo "$line"
            echo ""
            echo "<!-- Auto-tracked by SSM (updated: $TIMESTAMP) -->"
            # Get existing files from state that aren't in our new list
            # Then add our new files
            printf '%s' "$NEW_WORKING_FILES"
            WORKING_FILES_WRITTEN=true
        elif $IN_WORKING_FILES && [[ "$line" == "## "* ]]; then
            # Next section - end of Working Files
            IN_WORKING_FILES=false
            echo ""
            echo "$line"
        elif $IN_WORKING_FILES && [[ "$line" == "- "* ]]; then
            # Existing file entry - check if it's already in our new list
            EXISTING_FILE=$(echo "$line" | sed 's/^- //')
            if ! echo "$UNIQUE_FILES" | grep -qF "$EXISTING_FILE"; then
                echo "$line"
            fi
        elif $IN_WORKING_FILES && [[ "$line" == "<!--"* ]]; then
            # Skip old auto-track comments
            :
        elif ! $IN_WORKING_FILES; then
            echo "$line"
        fi
    done < "$STATE_FILE"
} > "$TEMP_FILE" 2>/dev/null

# Atomic replace
if [ -f "$TEMP_FILE" ] && [ -s "$TEMP_FILE" ]; then
    mv "$TEMP_FILE" "$STATE_FILE" 2>/dev/null || rm -f "$TEMP_FILE"
else
    rm -f "$TEMP_FILE" 2>/dev/null || true
fi

# Also update the timestamp in the state file
sed -i "s/^Updated:.*/Updated: $TIMESTAMP/" "$STATE_FILE" 2>/dev/null || true

# Output success (no visible message - this should be invisible to user)
echo '{"continue": true}'
