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
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
TRACKING_FILE="/tmp/ssm-modified-files-$SESSION_ID.txt"

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
fi

# Always allow the tool to proceed
echo '{"continue": true}'
