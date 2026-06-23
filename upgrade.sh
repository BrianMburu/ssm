#!/bin/bash
#
# Session State Manager (SSM) Upgrade Script
#
# Refreshes SSM BEHAVIOR files (hooks, commands, skills, agents, rules, scripts,
# hook registration, task templates) in an existing project — WITHOUT touching
# your live state or task data.
#
# Use this instead of setup.sh to update SSM in a project you're actively using.
# setup.sh is for FRESH installs: it does `cp -r .claude/*` which overwrites
# state/active.md and state/active-tasks.md and dumps example tasks — unsafe for
# an in-use project.
#
# NEVER touched by this script:
#   - .claude/state/                  (active.md, active-tasks.md, sessions/, completed/, locks/)
#   - tasks/<your-task-dirs>/         (only tasks/.templates/ is refreshed)
#   - CLAUDE.md
#   - .claude/settings.json           (preserved unless --with-settings; your permissions stay)
#
# Usage:
#   ./upgrade.sh /path/to/project              # refresh behavior files
#   ./upgrade.sh /path/to/project --dry-run    # show what would change, do nothing
#   ./upgrade.sh /path/to/project --with-settings  # also replace settings.json (backs up first)
#

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"
shift 2>/dev/null || true

DRY=false
WITH_SETTINGS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY=true; shift ;;
        --with-settings) WITH_SETTINGS=true; shift ;;
        --help|-h)
            sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⬆️  Session State Manager (SSM) Upgrade"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source: $SCRIPT_DIR"
echo "Target: $TARGET_DIR"
$DRY && echo -e "${YELLOW}DRY RUN — no files will be changed${NC}"
echo ""

if [ ! -d "$TARGET_DIR/.claude" ]; then
    echo -e "${RED}No .claude/ in target. This is for upgrading an existing install.${NC}"
    echo "For a fresh install use: ./setup.sh \"$TARGET_DIR\""
    exit 1
fi

# Behavior files/dirs that SSM owns. Lists mirror uninstall.sh so we only ever
# refresh SSM's own files and never clobber user-added skills/agents/commands.
SSM_SKILLS=(session-state task-management context-monitor multi-instance ssm)
SSM_AGENTS=(ssm-explorer.md ssm-planner.md)
SSM_RULE_DIRS=(ssm)
SSM_RULE_FILES=(state-management.md context-efficiency.md)

REFRESHED=0
do_cp() { # src dst
    local src="$1" dst="$2"
    [ -e "$src" ] || return 0
    if $DRY; then
        echo "    would update: ${dst#$TARGET_DIR/}"
    else
        mkdir -p "$(dirname "$dst")"
        cp -rf "$src" "$dst"
    fi
    REFRESHED=$((REFRESHED + 1))
}

echo -e "${CYAN}Refreshing behavior files (state & task data left untouched)...${NC}"

echo "  • hooks/"
for f in "$SCRIPT_DIR/.claude/hooks/"*.sh; do do_cp "$f" "$TARGET_DIR/.claude/hooks/$(basename "$f")"; done
do_cp "$SCRIPT_DIR/.claude/hooks.json" "$TARGET_DIR/.claude/hooks.json"

echo "  • commands/"
for f in "$SCRIPT_DIR/.claude/commands/"*.md; do do_cp "$f" "$TARGET_DIR/.claude/commands/$(basename "$f")"; done

echo "  • scripts/"
for f in "$SCRIPT_DIR/.claude/scripts/"*.sh; do do_cp "$f" "$TARGET_DIR/.claude/scripts/$(basename "$f")"; done

echo "  • skills/ (SSM-owned only)"
for s in "${SSM_SKILLS[@]}"; do do_cp "$SCRIPT_DIR/.claude/skills/$s" "$TARGET_DIR/.claude/skills/$s"; done

echo "  • agents/ (SSM-owned only)"
for a in "${SSM_AGENTS[@]}"; do do_cp "$SCRIPT_DIR/.claude/agents/$a" "$TARGET_DIR/.claude/agents/$a"; done

echo "  • rules/ (SSM-owned only)"
for d in "${SSM_RULE_DIRS[@]}"; do do_cp "$SCRIPT_DIR/.claude/rules/$d" "$TARGET_DIR/.claude/rules/$d"; done
for r in "${SSM_RULE_FILES[@]}"; do do_cp "$SCRIPT_DIR/.claude/rules/$r" "$TARGET_DIR/.claude/rules/$r"; done

echo "  • tasks/.templates/"
if [ -d "$SCRIPT_DIR/tasks/.templates" ]; then
    for f in "$SCRIPT_DIR/tasks/.templates/"*.md; do do_cp "$f" "$TARGET_DIR/tasks/.templates/$(basename "$f")"; done
fi

# Ensure runtime state dirs exist (create only; never wipe)
if ! $DRY; then
    mkdir -p "$TARGET_DIR/.claude/state/sessions" \
             "$TARGET_DIR/.claude/state/completed" \
             "$TARGET_DIR/.claude/state/locks"
    chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true
    chmod +x "$TARGET_DIR/.claude/scripts/"*.sh 2>/dev/null || true
    # Ensure locks/ is git-ignored (append if missing)
    if [ -f "$TARGET_DIR/.gitignore" ] && ! grep -q "state/locks" "$TARGET_DIR/.gitignore"; then
        echo ".claude/state/locks/" >> "$TARGET_DIR/.gitignore"
    fi
fi

# settings.json: preserve by default (it holds your permissions). Only replace
# with explicit opt-in, and back up first.
echo "  • settings.json"
if $WITH_SETTINGS; then
    if $DRY; then
        echo "    would back up settings.json → settings.json.bak and replace with template"
    else
        [ -f "$TARGET_DIR/.claude/settings.json" ] && cp "$TARGET_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json.bak"
        cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
        echo -e "    ${GREEN}replaced (backup at settings.json.bak)${NC}"
    fi
else
    if ! diff -q "$SCRIPT_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json" >/dev/null 2>&1; then
        echo -e "    ${YELLOW}preserved (differs from template — re-run with --with-settings to update hook registration if needed)${NC}"
    else
        echo "    unchanged"
    fi
fi

# Version stamp: report old → new and record it (canonical source: plugin.json)
OLD_VER=$(cat "$TARGET_DIR/.claude/.ssm-version" 2>/dev/null || echo "unknown")
NEW_VER=$(grep -m1 '"version"' "$SCRIPT_DIR/.claude-plugin/plugin.json" 2>/dev/null | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
echo "  • version"
if $DRY; then
    echo "    would stamp .claude/.ssm-version: ${OLD_VER} → ${NEW_VER:-?}"
elif [ -n "$NEW_VER" ]; then
    echo "$NEW_VER" > "$TARGET_DIR/.claude/.ssm-version" 2>/dev/null || true
    echo "    SSM version: ${OLD_VER} → ${NEW_VER}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if $DRY; then
    echo -e "${GREEN}✅ Dry run complete — $REFRESHED item(s) would be refreshed${NC}"
else
    echo -e "${GREEN}✅ Upgrade complete — $REFRESHED behavior item(s) refreshed (SSM ${NEW_VER:-?})${NC}"
fi
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Preserved (not touched):${NC} .claude/state/, your tasks/, CLAUDE.md"
echo "Restart Claude Code in the project for refreshed hooks to take effect."
