#!/bin/bash
#
# Session State Manager (SSM) Setup Script
# Installs the SSM template into your project
# Supports multi-instance mode with per-session state
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory (where the template lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directory (argument or current directory)
TARGET_DIR="${1:-.}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Session State Manager (SSM) Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${CYAN}Features:${NC}"
echo "  • Multi-instance support with session ownership rules"
echo "  • Full task structure (5 files) with progress.md as source of truth"
echo "  • Context warnings at 50%, 60%, 70%, 75% (auto-save at 75%)"
echo "  • Task registry and handoff coordination"
echo "  • Large tasks spanning multiple sessions supported"
echo ""
echo "Source: $SCRIPT_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Confirm if target exists and has files
if [ -d "$TARGET_DIR/.claude" ]; then
    echo -e "${YELLOW}⚠️  Warning: .claude directory already exists in target${NC}"
    read -p "Merge with existing? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Create target directory if needed
mkdir -p "$TARGET_DIR"

echo "Installing SSM components..."

# Copy .claude directory
echo "  → Copying .claude/"
mkdir -p "$TARGET_DIR/.claude"
cp -r "$SCRIPT_DIR/.claude/"* "$TARGET_DIR/.claude/"

# Ensure multi-instance directories exist
echo "  → Creating multi-instance directories"
mkdir -p "$TARGET_DIR/.claude/state/sessions"
mkdir -p "$TARGET_DIR/.claude/state/completed"
mkdir -p "$TARGET_DIR/.claude/state/locks"   # session heartbeats + per-task locks (runtime only)

# Copy tasks directory
echo "  → Copying tasks/"
mkdir -p "$TARGET_DIR/tasks"
cp -r "$SCRIPT_DIR/tasks/"* "$TARGET_DIR/tasks/" 2>/dev/null || true

# Copy CLAUDE.md if it doesn't exist
if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
    echo "  → Copying CLAUDE.md"
    cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
else
    echo -e "  → ${YELLOW}CLAUDE.md exists, skipping (manual merge may be needed)${NC}"
fi

# Make hooks executable
echo "  → Setting hook permissions"
chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$TARGET_DIR/.claude/scripts/"*.sh 2>/dev/null || true

# Update .gitignore
echo "  → Updating .gitignore"
if [ -f "$TARGET_DIR/.gitignore" ]; then
    if ! grep -q ".claude/cache/" "$TARGET_DIR/.gitignore"; then
        echo "" >> "$TARGET_DIR/.gitignore"
        echo "# SSM cache and session-specific files" >> "$TARGET_DIR/.gitignore"
        echo ".claude/cache/" >> "$TARGET_DIR/.gitignore"
        echo ".claude/state/sessions/*.md" >> "$TARGET_DIR/.gitignore"
        echo ".claude/state/locks/" >> "$TARGET_DIR/.gitignore"
    fi
else
    cat > "$TARGET_DIR/.gitignore" << 'GITIGNORE'
# SSM cache and session-specific files
.claude/cache/
.claude/state/sessions/*.md
.claude/state/locks/
GITIGNORE
fi

# Verify installation
echo ""
echo "Verifying installation..."

ERRORS=0
WARNINGS=0

# Core files
if [ ! -f "$TARGET_DIR/.claude/state/active.md" ]; then
    echo -e "  ${RED}✗ Missing: .claude/state/active.md${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "  ${GREEN}✓ .claude/state/active.md${NC}"
fi

if [ ! -f "$TARGET_DIR/.claude/state/active-tasks.md" ]; then
    echo -e "  ${RED}✗ Missing: .claude/state/active-tasks.md${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "  ${GREEN}✓ .claude/state/active-tasks.md (task registry)${NC}"
fi

if [ ! -f "$TARGET_DIR/.claude/settings.json" ]; then
    echo -e "  ${RED}✗ Missing: .claude/settings.json${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "  ${GREEN}✓ .claude/settings.json${NC}"
fi

# Hooks
if [ ! -x "$TARGET_DIR/.claude/hooks/session-start.sh" ]; then
    echo -e "  ${RED}✗ Not executable: .claude/hooks/session-start.sh${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "  ${GREEN}✓ Hooks are executable${NC}"
fi

# Multi-instance directories
if [ ! -d "$TARGET_DIR/.claude/state/sessions" ]; then
    echo -e "  ${RED}✗ Missing: .claude/state/sessions/ directory${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "  ${GREEN}✓ .claude/state/sessions/ (multi-instance)${NC}"
fi

if [ ! -d "$TARGET_DIR/.claude/state/completed" ]; then
    echo -e "  ${YELLOW}⚠ Missing: .claude/state/completed/ directory${NC}"
    mkdir -p "$TARGET_DIR/.claude/state/completed"
    echo -e "  ${GREEN}  → Created .claude/state/completed/${NC}"
fi

# Task templates
if [ ! -f "$TARGET_DIR/tasks/.templates/progress.md" ]; then
    echo -e "  ${YELLOW}⚠ Missing: task templates${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    TEMPLATE_COUNT=$(ls -1 "$TARGET_DIR/tasks/.templates/"*.md 2>/dev/null | wc -l)
    echo -e "  ${GREEN}✓ Task templates installed ($TEMPLATE_COUNT files)${NC}"
fi

# Skills
if [ ! -f "$TARGET_DIR/.claude/skills/session-state/SKILL.md" ]; then
    echo -e "  ${YELLOW}⚠ Missing: session-state skill${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "  ${GREEN}✓ Skills installed${NC}"
fi

if [ ! -f "$TARGET_DIR/.claude/skills/multi-instance/SKILL.md" ]; then
    echo -e "  ${YELLOW}⚠ Missing: multi-instance skill${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "  ${GREEN}✓ Multi-instance skill installed${NC}"
fi

if [ ! -f "$TARGET_DIR/.claude/skills/task-management/SKILL.md" ]; then
    echo -e "  ${YELLOW}⚠ Missing: task-management skill${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "  ${GREEN}✓ Task-management skill installed${NC}"
fi

# Commands
COMMANDS=("save-state" "continue-task" "new-task" "complete-task" "active-tasks" "claim-task" "release-task" "task-status" "task-history" "ssm-status")
MISSING_COMMANDS=0
for cmd in "${COMMANDS[@]}"; do
    if [ ! -f "$TARGET_DIR/.claude/commands/$cmd.md" ]; then
        MISSING_COMMANDS=$((MISSING_COMMANDS + 1))
    fi
done
if [ $MISSING_COMMANDS -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ Missing $MISSING_COMMANDS commands${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "  ${GREEN}✓ All commands installed (${#COMMANDS[@]} commands)${NC}"
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ SSM installed successfully!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}   ($WARNINGS warnings - see above)${NC}"
    fi
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Edit CLAUDE.md to add your project details"
    echo "  2. Start Claude Code in your project"
    echo "  3. Use /new-task to create your first task"
    echo ""
    echo -e "${CYAN}IMPORTANT - Context Thresholds:${NC}"
    echo "  < 50%   Safe zone"
    echo "  50-60%  Good checkpoint opportunity"
    echo "  60-70%  Plan to save soon"
    echo "  70-75%  ${YELLOW}Finish step, then save+clear${NC}"
    echo "  > 75%   ${RED}SAVE NOW - 5k to danger zone${NC}"
    echo ""
    echo -e "${CYAN}Key Concepts:${NC}"
    echo "  • progress.md is source of truth (not TodoWrite)"
    echo "  • Large tasks spanning sessions is NORMAL"
    echo "  • Never modify tasks owned by other sessions"
    echo ""
    echo -e "${CYAN}Task Lifecycle:${NC}"
    echo "  /new-task <id>   - Create task (5 files)"
    echo "  /task-status     - Show progress from progress.md"
    echo "  /complete-task   - Mark done and archive"
    echo ""
    echo -e "${CYAN}Session Management:${NC}"
    echo "  /save-state      - Save before /clear"
    echo "  /continue-task   - Continue from saved state"
    echo ""
    echo -e "${CYAN}Multi-Instance:${NC}"
    echo "  /active-tasks    - View ALL tasks across terminals"
    echo "  /claim-task <id> - Take over from another session"
    echo "  /release-task    - Pause for others to claim"
    echo ""
    echo -e "${CYAN}Built-in Commands:${NC}"
    echo "  /context         - View context usage"
    echo "  /clear           - Clear and start fresh"
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}⚠️  Installation completed with $ERRORS error(s)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Please fix the errors above before using SSM."
fi
