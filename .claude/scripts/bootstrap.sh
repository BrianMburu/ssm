#!/bin/bash
#
# SSM bootstrap — materialize the project-side scaffolding that the plugin
# install mechanism does NOT deliver: state files, task templates, and rules.
#
# A Claude Code plugin ships commands/skills/agents/hooks, but a project still
# needs .claude/state/, tasks/.templates/, and .claude/rules/ to function.
# This runs on first SessionStart of a plugin install (see session-start.sh).
#
# Idempotent and NON-DESTRUCTIVE: only creates what is missing; never
# overwrites existing project state. For manual (setup.sh) installs this never
# runs — the scaffolding already exists and CLAUDE_PLUGIN_ROOT is unset.
#
# Usage: bootstrap.sh <project-dir> <plugin-root>
#

# DO NOT use set -e — must degrade gracefully, never break the session.

PROJECT_DIR="$1"
PLUGIN_ROOT="$2"
[ -n "$PROJECT_DIR" ] || exit 0
[ -n "$PLUGIN_ROOT" ] || exit 0
SRC="$PLUGIN_ROOT/.claude"

# 1) State directories
mkdir -p "$PROJECT_DIR/.claude/state/sessions" \
         "$PROJECT_DIR/.claude/state/completed" \
         "$PROJECT_DIR/.claude/state/locks" 2>/dev/null || true

# 2) Seed top-level state files (only if missing)
for f in active.md active-tasks.md context-registry.md; do
    [ -f "$PROJECT_DIR/.claude/state/$f" ] || \
        cp "$SRC/state/$f" "$PROJECT_DIR/.claude/state/$f" 2>/dev/null || true
done
[ -f "$PROJECT_DIR/.claude/state/sessions/.session-template.md" ] || \
    cp "$SRC/state/sessions/.session-template.md" \
       "$PROJECT_DIR/.claude/state/sessions/.session-template.md" 2>/dev/null || true

# 3) Task templates
mkdir -p "$PROJECT_DIR/tasks/.templates" 2>/dev/null || true
for f in task plan progress context decisions; do
    [ -f "$PROJECT_DIR/tasks/.templates/$f.md" ] || \
        cp "$PLUGIN_ROOT/tasks/.templates/$f.md" \
           "$PROJECT_DIR/tasks/.templates/$f.md" 2>/dev/null || true
done

# 4) Rules — plugins cannot contribute project rules, so copy them in so they
#    auto-load as project instructions (takes effect from the next session).
if [ ! -d "$PROJECT_DIR/.claude/rules/ssm" ]; then
    mkdir -p "$PROJECT_DIR/.claude/rules" 2>/dev/null || true
    cp -r "$SRC/rules/." "$PROJECT_DIR/.claude/rules/" 2>/dev/null || true
fi

# 5) Version stamp
if [ ! -f "$PROJECT_DIR/.claude/.ssm-version" ]; then
    V=$(grep -m1 '"version"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null \
        | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    [ -n "$V" ] && echo "$V" > "$PROJECT_DIR/.claude/.ssm-version" 2>/dev/null || true
fi

exit 0
