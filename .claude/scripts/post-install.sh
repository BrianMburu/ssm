#!/bin/bash
# SSM Post-Install Script
# Creates necessary directories and initializes state files

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "SSM: Initializing session state directories..."

# Create state directories
mkdir -p "$PROJECT_DIR/.claude/state/sessions"
mkdir -p "$PROJECT_DIR/.claude/state/completed"

# Create tasks directory with templates
mkdir -p "$PROJECT_DIR/tasks/.templates"

# Initialize active-tasks.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/.claude/state/active-tasks.md" ]; then
  cat > "$PROJECT_DIR/.claude/state/active-tasks.md" << 'EOF'
# Active Tasks Registry

Tracks all tasks across Claude Code sessions.

## Currently Active

| Task ID | Session | Status | Started | Last Updated |
|---------|---------|--------|---------|--------------|

## Recently Completed

| Task ID | Completed | Summary |
|---------|-----------|---------|

## Paused / Available for Claim

| Task ID | Last Session | Paused At | Notes |
|---------|--------------|-----------|-------|
EOF
  echo "SSM: Created active-tasks.md"
fi

# Initialize context-registry.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/.claude/state/context-registry.md" ]; then
  cat > "$PROJECT_DIR/.claude/state/context-registry.md" << 'EOF'
# Context Registry

Token estimates for common files. Updated as files are loaded.

| File | Est. Tokens | Last Loaded | Notes |
|------|-------------|-------------|-------|
EOF
  echo "SSM: Created context-registry.md"
fi

# Make hook scripts executable
chmod +x "$PROJECT_DIR/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_DIR/.claude/scripts/"*.sh 2>/dev/null || true

echo "SSM: Installation complete!"
echo ""
echo "Quick Start:"
echo "  - State auto-loads on session start"
echo "  - Use /new-task <name> to create a task"
echo "  - Use /save-state before /clear"
echo "  - Use /continue-task to resume"
echo ""
echo "See /ssm-status for current state."
