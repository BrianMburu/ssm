---
name: context-monitor
description: Monitors context usage and provides proactive recommendations. Use when context might be getting high, when loading many files, or when user asks about context or memory usage.
allowed-tools: Read, Bash(cat:*), Bash(wc:*)
---

# Context Monitor Skill

This skill helps manage context window usage proactively.

## When to Activate

Automatically activate when:
- Loading multiple files
- User mentions "context", "memory", or "tokens"
- Working on a task for extended time
- Before large file reads

## Using Built-in `/context`

Claude Code has a built-in `/context` command that shows context usage as a colored grid. **Use this first** for accurate readings.

```
/context
```

## Warning Thresholds

| Level | Percentage | Recommendation |
|-------|------------|----------------|
| 🟢 Green | < 60% | Normal operation |
| 🟡 Yellow | 60-70% | Be mindful of new loads |
| 🟠 Orange | 70-80% | Finish current step, then save |
| 🔴 Red | 80-90% | Save state immediately |
| ⚫ Critical | > 90% | Emergency save, auto-compact imminent |

## Context-Efficient Practices

### Load Priority

1. **Essential** - Files being directly modified
2. **Reference** - Load on demand, unload after
3. **Never Load** - Deprecated or processed files

### Token Estimation

Rough estimate: ~4 characters per token

```bash
# Estimate file tokens
wc -c filename | awk '{print int($1/4) " tokens (est.)"}'
```

### Smart Loading

- Use line ranges when possible: `Read file.ts:10-50`
- Load types/interfaces before implementations
- Skip files marked "Do NOT Load" in active.md

## When Context is High

1. **Don't panic** - Complete current atomic action
2. **Save state** - Run `/save-state` command
3. **Clear context** - Run `/clear`
4. **State auto-loads** - Session-start hook reloads state

## Context Registry

The `.claude/state/context-registry.md` tracks file relevance per task:
- Essential files (always load)
- Reference files (on demand)
- Deprecated files (never load)

Update this as you work to help future sessions.

## Avoiding Auto-Compaction

Auto-compaction degrades context quality. Prevent it by:
1. Monitoring context proactively
2. Saving state before 80%
3. Using `/clear` for fresh context
4. Letting session-start hook reload state

## Integration Notes

- `/context` - Built-in, use for accurate readings
- `/compact` - Avoid if possible, degrades quality
- `/clear` - Preferred for fresh start
- `/continue-task` - Our command to reload task state
