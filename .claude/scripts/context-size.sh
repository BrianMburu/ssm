#!/bin/bash
#
# Context Size Estimation Script
# Estimates token count for files to help with context budgeting
#
# Usage: ./context-size.sh [file or directory]
#

# Don't use set -e for robustness

TARGET="${1:-.}"

# Rough estimation: ~4 characters per token on average for code
CHARS_PER_TOKEN=4

estimate_tokens() {
    local file="$1"
    if [ -f "$file" ]; then
        local chars=$(wc -c < "$file" 2>/dev/null || echo "0")
        local tokens=$((chars / CHARS_PER_TOKEN))
        echo "$tokens"
    else
        echo "0"
    fi
}

if [ -f "$TARGET" ]; then
    # Single file
    TOKENS=$(estimate_tokens "$TARGET")
    echo "$TARGET: ~$TOKENS tokens"
elif [ -d "$TARGET" ]; then
    # Directory
    echo "Token estimates for: $TARGET"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    TOTAL=0
    
    # Find code files (excluding common non-code)
    find "$TARGET" -type f \( \
        -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
        -o -name "*.py" -o -name "*.go" -o -name "*.rs" \
        -o -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \
        \) 2>/dev/null | grep -v node_modules | grep -v ".git" | sort | while IFS= read -r file; do
        if [ -f "$file" ]; then
            TOKENS=$(estimate_tokens "$file")
            TOTAL=$((TOTAL + TOKENS))
            printf "%6d tokens  %s\n" "$TOKENS" "$file"
        fi
    done
    
    # Calculate total separately (subshell issue with while loop)
    TOTAL=$(find "$TARGET" -type f \( \
        -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
        -o -name "*.py" -o -name "*.go" -o -name "*.rs" \
        -o -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \
        \) 2>/dev/null | grep -v node_modules | grep -v ".git" | while IFS= read -r file; do
        wc -c < "$file" 2>/dev/null || echo "0"
    done | awk '{sum+=$1} END {print int(sum/4)}')
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total: ~${TOTAL:-0} tokens"
    echo ""
    echo "Note: This is a rough estimate (~4 chars/token)."
    echo "Actual token count may vary by ±20%."
else
    echo "Error: $TARGET not found"
    exit 1
fi
