# Context Efficiency Rules

Guidelines for maintaining high-quality context while minimizing token usage.

## Critical: Context Window Limits

**Total context window**: 200k tokens
**Auto-compact buffer**: ~45k tokens (22.5%)
**Danger zone starts at**: 77.5% (155k tokens)

Auto-compaction can trigger once you enter the buffer zone. SSM blocks it, but you MUST clear context before this point to maintain quality.

## Warning Thresholds (Adjusted for 45k Buffer)

| Level | Percentage | Tokens | Action |
|-------|-----------|--------|--------|
| Green | < 50% | < 100k | Normal operation |
| Notice | 50-60% | 100-120k | Good checkpoint opportunity |
| Warning | 60-70% | 120-140k | Plan to save soon |
| **Strong** | 70-75% | 140-150k | Finish step, then save+clear |
| **CRITICAL** | > 75% | > 150k | **SAVE NOW** - 5k to danger |
| Danger | > 77.5% | > 155k | In buffer - too late |

**Key insight**: Our old 90% threshold was WRONG. By 80% you're already in the danger zone.

## Token Budget Guidelines

| Context Level | Token Budget | Use Case |
|--------------|--------------|----------|
| Minimal | < 50k (25%) | Quick fixes, single file changes |
| Standard | 50-100k (25-50%) | Normal feature work |
| Extended | 100-140k (50-70%) | Complex refactoring |
| Maximum | 140-150k (70-75%) | Large changes, then MUST clear |

**Rule**: Plan checkpoints at 60-70% to allow graceful save+clear.

## Large Tasks Span Sessions

**This is NORMAL and EXPECTED:**
- A complex feature may require 3-5 sessions
- Each session: load state → work → save state → clear
- Progress is preserved in `progress.md` and `plan.md`
- No context degradation from compaction

**Do NOT try to**:
- Complete large tasks in one session
- Ignore context warnings
- Push past 75% without clearing

## File Loading Rules

### Load Priority

1. **Essential** (Always load)
   - Files being directly modified
   - Type definitions for those files
   - Test files for current work

2. **Reference** (Load on demand)
   - Documentation
   - Example patterns
   - Related but not directly modified files

3. **Never Load** (Skip these)
   - Files marked "Deprecated" in context.md
   - Completed research documents
   - Build outputs and generated files
   - node_modules, vendor, etc.

### Loading Best Practices

**Do**:
- Load only what's needed for current step
- Use file slices (specific line ranges) when possible
- Check task's `context.md` for token estimates
- Unload files after using them

**Don't**:
- Load entire directories "just in case"
- Keep research documents loaded after research phase
- Load test files when not writing tests
- Load configuration files unless modifying them

## Context-Aware Planning

Every `plan.md` should include:

```markdown
### Phase X: [Name]
Estimated context: ~Xk tokens
Checkpoint: Yes/No (good place to save+clear)
```

Recommended checkpoint phases:
- After research/exploration
- After major implementation milestones
- Before testing phase
- When context reaches 60-70%

## Session Scope

### One Task Per Session

**Rule**: Each session focuses on one task at a time.

**Why**:
- Keeps context relevant
- Cleaner state management
- Easier to track progress
- Simpler to resume

### Natural Session Lifecycle

```
1. Session starts → load state from active.md
2. Work on current phase → update progress.md
3. Context reaches 60-70% → finish current step
4. Save state → /save-state
5. Clear → /clear
6. New session → state auto-loads, continue
```

## Compression Prevention

### Why We Block Compaction

Each compression:
- Loses specific details
- Merges distinct concepts
- Reduces code accuracy
- Degrades decision context

After 2-3 compressions, Claude works with "gist" not "specifics".

### Prevention Strategy

1. **Proactive Clearing**: Save and clear at 70%, not 90%
2. **Structured State**: Write to files, not conversation
3. **Selective Loading**: Only load what's needed now
4. **Regular Checkpoints**: Plan saves at natural breakpoints

## Recovery Patterns

### After Emergency (Hit 75%+)

1. Auto-checkpoint created in `.claude/state/checkpoints/`
2. Run `/save-state` immediately
3. Run `/clear`
4. State auto-loads on new session
5. Continue from where you left off

### After Long Break

1. Run `/continue-task` to load state
2. Review `progress.md` for current status
3. Check `plan.md` for next phase
4. Update state if priorities changed
