---
name: context-monitor
description: Monitors context usage and warns about limits. Activates on "context", "memory", "tokens", "how much space", "running out of", "almost full", or when loading many files.
allowed-tools: Read, Bash(wc:*)
---

# Context Monitor Skill

Proactively manages context window usage to prevent degradation.

## When to Auto-Activate

**Direct Questions:**
- "How's my context?" / "Context usage?"
- "How much memory/space left?"
- "Am I running low on tokens?"
- "Is context almost full?"

**Implicit Triggers:**
- Loading multiple large files
- Working for extended time without clearing
- Before reading a very large file

## Quick Status Check

Use Claude Code's built-in command:
```
/context
```

Shows colored grid with current usage.

## Warning Thresholds (Adjusted for 45k Buffer)

**CRITICAL**: Auto-compact buffer is ~45k tokens (22.5%). Danger zone starts at 77.5%.

| Level | Range | Tokens | Action |
|-------|-------|--------|--------|
| Green | < 50% | < 100k | Normal work |
| Notice | 50-60% | 100-120k | Good checkpoint opportunity |
| Warning | 60-70% | 120-140k | Plan to save soon |
| **Strong** | 70-75% | 140-150k | Finish step, then save+clear |
| **CRITICAL** | > 75% | > 150k | **SAVE NOW** - 5k to danger |
| Danger | > 77.5% | > 155k | In buffer zone - too late |

**Why 75% not 90%?** The old thresholds were wrong. At 80% you're already in danger.

## When Context is High

1. **Complete current step** (don't leave work half-done)
2. **Run `/save-state`** to preserve progress
3. **Run `/clear`** to start fresh
4. State auto-reloads on new session

## Auto-Protection

SSM provides automatic protection:
- **PreCompact hook**: Blocks compaction entirely
- **Context-check hook**: Warns at 50%, 60%, 70%, 75% (auto-save at 75%)
- **PreToolUse hook**: Auto-tracks working files

## Efficient Practices

**Do:**
- Load only files you're actively editing
- Use line ranges: `Read file.ts:10-50`
- Unload files after using them
- Use Explorer subagent for research (isolates context)

**Don't:**
- Load entire directories
- Keep research docs after research
- Load files "just in case"

## Subagents for Context Isolation

When you need to explore the codebase, use the Explorer subagent to keep exploration noise out of main context:

```
Task tool:
- subagent_type: "Explore"
- prompt: "Find all files related to X and summarize"
- model: "haiku" (faster for simple searches)
```

Only the summary returns to main context, not all the files read during exploration.

## Token Estimation

Rough guide: ~4 characters = 1 token

```bash
# Estimate file size
wc -c file.ts  # Divide by 4 for tokens
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `/context` | View current usage |
| `/save-state` | Save before clearing |
| `/clear` | Fresh context |
