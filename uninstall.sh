#!/bin/bash
#
# Session State Manager (SSM) Uninstall Script
# Removes only SSM-specific files, preserving user-created content
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Target directory (argument or current directory)
TARGET_DIR="${1:-.}"

# Flags
KEEP_TASKS=false
KEEP_STATE=false
FORCE=false

# Parse arguments
shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-tasks)
            KEEP_TASKS=true
            shift
            ;;
        --keep-state)
            KEEP_STATE=true
            shift
            ;;
        --keep-data)
            KEEP_TASKS=true
            KEEP_STATE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            echo "Usage: uninstall.sh [target-dir] [options]"
            echo ""
            echo "Options:"
            echo "  --keep-tasks    Preserve tasks/ directory"
            echo "  --keep-state    Preserve .claude/state/ files"
            echo "  --keep-data     Preserve both tasks and state (same as --keep-tasks --keep-state)"
            echo "  --force, -f     Skip confirmation prompts"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./uninstall.sh /path/to/project              # Full uninstall"
            echo "  ./uninstall.sh /path/to/project --keep-data  # Keep tasks and state"
            echo "  ./uninstall.sh . --force                     # Uninstall current dir, no prompts"
            echo ""
            echo "Note: This script only removes SSM-specific files."
            echo "      User-created skills, agents, commands, etc. are preserved."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Session State Manager (SSM) Uninstall"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Target: $TARGET_DIR"
echo ""

# Check if SSM is installed
if [ ! -d "$TARGET_DIR/.claude" ]; then
    echo -e "${YELLOW}SSM does not appear to be installed in this directory.${NC}"
    echo "No .claude/ directory found."
    exit 0
fi

# Define SSM-specific files and directories
# These are the only things we'll remove

# SSM hooks
SSM_HOOKS=(
    "session-start.sh"
    "context-check.sh"
    "pre-compact.sh"
    "post-tool-use.sh"
    "track-changes.sh"
    "stop-hook.sh"
)

# SSM commands
SSM_COMMANDS=(
    "save-state.md"
    "continue-task.md"
    "new-task.md"
    "task-status.md"
    "ssm-status.md"
    "complete-task.md"
    "active-tasks.md"
    "claim-task.md"
    "release-task.md"
    "task-history.md"
    "start.md"
)

# SSM task templates
SSM_TEMPLATES=(
    "task.md"
    "plan.md"
    "progress.md"
    "context.md"
    "decisions.md"
)

# SSM skills (directories)
SSM_SKILLS=(
    "session-state"
    "task-management"
    "context-monitor"
    "multi-instance"
    "ssm"
)

# SSM agents
SSM_AGENTS=(
    "ssm-explorer.md"
    "ssm-planner.md"
)

# SSM rules (directories)
SSM_RULES=(
    "ssm"
    "state-management.md"
    "context-efficiency.md"
)

# SSM scripts
SSM_SCRIPTS=(
    "status.sh"
    "context-size.sh"
    "post-install.sh"
)

# Count what will be removed
echo -e "${CYAN}Scanning for SSM components...${NC}"
echo ""

HOOKS_TO_REMOVE=()
for hook in "${SSM_HOOKS[@]}"; do
    if [ -f "$TARGET_DIR/.claude/hooks/$hook" ]; then
        HOOKS_TO_REMOVE+=("$hook")
    fi
done

COMMANDS_TO_REMOVE=()
for cmd in "${SSM_COMMANDS[@]}"; do
    if [ -f "$TARGET_DIR/.claude/commands/$cmd" ]; then
        COMMANDS_TO_REMOVE+=("$cmd")
    fi
done

SKILLS_TO_REMOVE=()
for skill in "${SSM_SKILLS[@]}"; do
    if [ -d "$TARGET_DIR/.claude/skills/$skill" ]; then
        SKILLS_TO_REMOVE+=("$skill")
    fi
done

AGENTS_TO_REMOVE=()
for agent in "${SSM_AGENTS[@]}"; do
    if [ -f "$TARGET_DIR/.claude/agents/$agent" ]; then
        AGENTS_TO_REMOVE+=("$agent")
    fi
done

RULES_TO_REMOVE=()
for rule in "${SSM_RULES[@]}"; do
    if [ -d "$TARGET_DIR/.claude/rules/$rule" ]; then
        RULES_TO_REMOVE+=("$rule/")
    elif [ -f "$TARGET_DIR/.claude/rules/$rule" ]; then
        RULES_TO_REMOVE+=("$rule")
    fi
done

SCRIPTS_TO_REMOVE=()
for script in "${SSM_SCRIPTS[@]}"; do
    if [ -f "$TARGET_DIR/.claude/scripts/$script" ]; then
        SCRIPTS_TO_REMOVE+=("$script")
    fi
done

TEMPLATES_TO_REMOVE=()
for template in "${SSM_TEMPLATES[@]}"; do
    if [ -f "$TARGET_DIR/tasks/.templates/$template" ]; then
        TEMPLATES_TO_REMOVE+=("$template")
    fi
done

# Show what will be removed
echo -e "${CYAN}Will remove SSM-specific files:${NC}"
echo ""

if [ ${#HOOKS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  Hooks (${#HOOKS_TO_REMOVE[@]}):"
    for item in "${HOOKS_TO_REMOVE[@]}"; do
        echo "    • .claude/hooks/$item"
    done
fi

if [ ${#COMMANDS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  Commands (${#COMMANDS_TO_REMOVE[@]}):"
    for item in "${COMMANDS_TO_REMOVE[@]}"; do
        echo "    • .claude/commands/$item"
    done
fi

if [ ${#SKILLS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  Skills (${#SKILLS_TO_REMOVE[@]}):"
    for item in "${SKILLS_TO_REMOVE[@]}"; do
        echo "    • .claude/skills/$item/"
    done
fi

if [ ${#AGENTS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  Agents (${#AGENTS_TO_REMOVE[@]}):"
    for item in "${AGENTS_TO_REMOVE[@]}"; do
        echo "    • .claude/agents/$item"
    done
fi

if [ ${#RULES_TO_REMOVE[@]} -gt 0 ]; then
    echo "  Rules (${#RULES_TO_REMOVE[@]}):"
    for item in "${RULES_TO_REMOVE[@]}"; do
        echo "    • .claude/rules/$item"
    done
fi

if [ ${#SCRIPTS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  Scripts (${#SCRIPTS_TO_REMOVE[@]}):"
    for item in "${SCRIPTS_TO_REMOVE[@]}"; do
        echo "    • .claude/scripts/$item"
    done
fi

if [ ${#TEMPLATES_TO_REMOVE[@]} -gt 0 ]; then
    echo "  Task Templates (${#TEMPLATES_TO_REMOVE[@]}):"
    for item in "${TEMPLATES_TO_REMOVE[@]}"; do
        echo "    • tasks/.templates/$item"
    done
fi

# Config files
echo "  Config files:"
[ -f "$TARGET_DIR/.claude/hooks.json" ] && echo "    • .claude/hooks.json"
[ -d "$TARGET_DIR/.claude-plugin" ] && echo "    • .claude-plugin/"

echo ""

# State and tasks
if [ "$KEEP_STATE" = false ]; then
    echo "  State files:"
    echo "    • .claude/state/ (entire directory)"
else
    echo -e "  ${GREEN}State files: PRESERVED${NC}"
fi

if [ "$KEEP_TASKS" = false ]; then
    echo "  Task files:"
    echo "    • tasks/ (entire directory)"
else
    echo -e "  ${GREEN}Task files: PRESERVED${NC}"
fi

echo ""

# Show what will be preserved
echo -e "${GREEN}Will preserve user content:${NC}"

# Check for non-SSM hooks
OTHER_HOOKS=$(ls "$TARGET_DIR/.claude/hooks/" 2>/dev/null | grep -v -E "^($(IFS='|'; echo "${SSM_HOOKS[*]}"))$" || true)
if [ -n "$OTHER_HOOKS" ]; then
    echo "  Other hooks:"
    echo "$OTHER_HOOKS" | while read -r item; do
        [ -n "$item" ] && echo "    • .claude/hooks/$item"
    done
fi

# Check for non-SSM commands
OTHER_COMMANDS=$(ls "$TARGET_DIR/.claude/commands/" 2>/dev/null | grep -v -E "^($(IFS='|'; echo "${SSM_COMMANDS[*]}"))$" || true)
if [ -n "$OTHER_COMMANDS" ]; then
    echo "  Other commands:"
    echo "$OTHER_COMMANDS" | while read -r item; do
        [ -n "$item" ] && echo "    • .claude/commands/$item"
    done
fi

# Check for non-SSM skills
OTHER_SKILLS=$(ls "$TARGET_DIR/.claude/skills/" 2>/dev/null | grep -v -E "^($(IFS='|'; echo "${SSM_SKILLS[*]}"))$" || true)
if [ -n "$OTHER_SKILLS" ]; then
    echo "  Other skills:"
    echo "$OTHER_SKILLS" | while read -r item; do
        [ -n "$item" ] && echo "    • .claude/skills/$item/"
    done
fi

# Check for non-SSM agents
OTHER_AGENTS=$(ls "$TARGET_DIR/.claude/agents/" 2>/dev/null | grep -v -E "^($(IFS='|'; echo "${SSM_AGENTS[*]}"))$" || true)
if [ -n "$OTHER_AGENTS" ]; then
    echo "  Other agents:"
    echo "$OTHER_AGENTS" | while read -r item; do
        [ -n "$item" ] && echo "    • .claude/agents/$item"
    done
fi

echo ""

# Check for active tasks
if [ -f "$TARGET_DIR/.claude/state/active-tasks.md" ] && [ "$KEEP_STATE" = false ]; then
    ACTIVE_COUNT=$(grep -c "IN_PROGRESS" "$TARGET_DIR/.claude/state/active-tasks.md" 2>/dev/null || echo "0")
    if [ "$ACTIVE_COUNT" != "0" ]; then
        echo -e "${YELLOW}⚠️  Warning: Found active task(s) in state${NC}"
        echo "   Consider using --keep-state or completing tasks first."
        echo ""
    fi
fi

# Confirmation
if [ "$FORCE" = false ]; then
    read -p "Proceed with uninstall? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    echo ""
fi

echo "Uninstalling SSM components..."

# Remove SSM hooks
if [ ${#HOOKS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  → Removing SSM hooks..."
    for hook in "${HOOKS_TO_REMOVE[@]}"; do
        rm -f "$TARGET_DIR/.claude/hooks/$hook"
    done
fi

# Remove SSM commands
if [ ${#COMMANDS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  → Removing SSM commands..."
    for cmd in "${COMMANDS_TO_REMOVE[@]}"; do
        rm -f "$TARGET_DIR/.claude/commands/$cmd"
    done
fi

# Remove SSM skills
if [ ${#SKILLS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  → Removing SSM skills..."
    for skill in "${SKILLS_TO_REMOVE[@]}"; do
        rm -rf "$TARGET_DIR/.claude/skills/$skill"
    done
fi

# Remove SSM agents
if [ ${#AGENTS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  → Removing SSM agents..."
    for agent in "${AGENTS_TO_REMOVE[@]}"; do
        rm -f "$TARGET_DIR/.claude/agents/$agent"
    done
fi

# Remove SSM rules
if [ ${#RULES_TO_REMOVE[@]} -gt 0 ]; then
    echo "  → Removing SSM rules..."
    for rule in "${SSM_RULES[@]}"; do
        rm -rf "$TARGET_DIR/.claude/rules/$rule"
    done
fi

# Remove SSM scripts
if [ ${#SCRIPTS_TO_REMOVE[@]} -gt 0 ]; then
    echo "  → Removing SSM scripts..."
    for script in "${SCRIPTS_TO_REMOVE[@]}"; do
        rm -f "$TARGET_DIR/.claude/scripts/$script"
    done
fi

# Remove SSM task templates
if [ ${#TEMPLATES_TO_REMOVE[@]} -gt 0 ]; then
    echo "  → Removing SSM task templates..."
    for template in "${TEMPLATES_TO_REMOVE[@]}"; do
        rm -f "$TARGET_DIR/tasks/.templates/$template"
    done
    # Remove .templates directory if empty
    rmdir "$TARGET_DIR/tasks/.templates" 2>/dev/null || true
fi

# Remove config files
echo "  → Removing SSM config files..."
rm -f "$TARGET_DIR/.claude/hooks.json"
rm -rf "$TARGET_DIR/.claude-plugin"

# Handle state
if [ "$KEEP_STATE" = false ]; then
    echo "  → Removing state directory..."
    rm -rf "$TARGET_DIR/.claude/state"
fi

# Handle tasks
if [ "$KEEP_TASKS" = false ]; then
    echo "  → Removing tasks directory..."
    rm -rf "$TARGET_DIR/tasks"
fi

# Clean up empty directories
echo "  → Cleaning up empty directories..."
rmdir "$TARGET_DIR/.claude/hooks" 2>/dev/null || true
rmdir "$TARGET_DIR/.claude/commands" 2>/dev/null || true
rmdir "$TARGET_DIR/.claude/skills" 2>/dev/null || true
rmdir "$TARGET_DIR/.claude/agents" 2>/dev/null || true
rmdir "$TARGET_DIR/.claude/rules" 2>/dev/null || true
rmdir "$TARGET_DIR/.claude/scripts" 2>/dev/null || true
rmdir "$TARGET_DIR/.claude" 2>/dev/null || true

# Clean up .gitignore entries
if [ -f "$TARGET_DIR/.gitignore" ]; then
    echo "  → Cleaning .gitignore..."
    sed -i '/# SSM cache and session-specific files/d' "$TARGET_DIR/.gitignore" 2>/dev/null || true
    sed -i '/\.claude\/cache\//d' "$TARGET_DIR/.gitignore" 2>/dev/null || true
    sed -i '/\.claude\/state\/sessions\/\*\.md/d' "$TARGET_DIR/.gitignore" 2>/dev/null || true
fi

# Update settings.json to remove SSM hooks (if file still exists and has other content)
if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
    echo "  → Note: settings.json may need manual cleanup of SSM hook references"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ SSM uninstalled successfully${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$KEEP_STATE" = true ] || [ "$KEEP_TASKS" = true ]; then
    echo "Preserved:"
    [ "$KEEP_STATE" = true ] && echo "  • .claude/state/"
    [ "$KEEP_TASKS" = true ] && echo "  • tasks/"
    echo ""
fi

echo "To reinstall SSM:"
echo "  ./setup.sh $TARGET_DIR"
echo ""
echo -e "${YELLOW}Note: You may want to remove the SSM section from CLAUDE.md manually.${NC}"
echo -e "${YELLOW}      Also check .claude/settings.json for any remaining SSM hook references.${NC}"
