# Context Efficiency Rules

Guidelines for maintaining high-quality context while minimizing token usage.

## Token Budget Guidelines

| Context Level | Token Budget | Use Case |
|--------------|--------------|----------|
| Minimal | < 2,000 | Quick fixes, single file changes |
| Standard | 2,000 - 5,000 | Normal feature work |
| Extended | 5,000 - 10,000 | Complex refactoring |
| Maximum | 10,000+ | Major architectural changes |

**Rule**: Stay at the minimum level needed for the current task.

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
   - Files marked "Deprecated" in context-registry.md
   - Completed research documents
   - Build outputs and generated files
   - node_modules, vendor, etc.

### Loading Best Practices

**Do**:
- Load only what's needed for current step
- Use file slices (specific line ranges) when possible
- Reference context-registry.md for token estimates
- Unload files after using them

**Don't**:
- Load entire directories "just in case"
- Keep research documents loaded after research phase
- Load test files when not writing tests
- Load configuration files unless modifying them

## Context Monitoring

### Warning Thresholds

| Level | Percentage | Action |
|-------|------------|--------|
| Green | < 60% | Normal operation |
| Yellow | 60-70% | Be mindful, consider what to load next |
| Orange | 70-80% | Finish current item, then save + clear |
| Red | 80-90% | Save state immediately |
| Critical | > 90% | Emergency save, auto-compact imminent |

### Monitoring Commands

```bash
# Check current context (status line shows this)
# Format: 🟢 45% | main U:3 | task | phase

# Manual check if status line unavailable
/context-check
```

## Information Density

### High-Value Context

Prioritize loading:
- Type definitions and interfaces
- Function signatures (not implementations)
- Test assertions (expected behavior)
- API contracts

### Low-Value Context

Avoid loading:
- Long implementation files entirely
- Verbose configuration
- Build scripts (unless debugging builds)
- Documentation not relevant to current task

## Session Scope

### One Task Per Session

**Rule**: Each session focuses on one task at a time.

**Why**:
- Keeps context relevant
- Cleaner state management
- Easier to track progress
- Simpler to resume

### Task Handoff

When switching tasks:
1. Complete or pause current task
2. Run `/save-state`
3. Run `/clear`
4. Start new task with `/new-task` or `/continue-task`

## Compression Prevention

### Why Prevent Compression

Each compression:
- Loses specific details
- Merges distinct concepts
- Reduces code accuracy
- Degrades decision context

After 2-3 compressions, Claude is working with "gist" not "specifics".

### Prevention Strategy

1. **Proactive Clearing**: Save and clear before compression triggers
2. **Structured State**: Write to files, not conversation
3. **Selective Loading**: Only load what's needed now
4. **Regular Checkpoints**: Save state at natural breakpoints

## Recovery Patterns

### After Auto-Compression

If compression happens despite prevention:

1. An auto-handoff was created in `tasks/<id>/handoffs/`
2. Review the auto-handoff for captured state
3. Run `/continue-task` to reload from active.md
4. Supplement with manual review if needed

### After Long Break

1. Run `/continue-task` to load state
2. Run `/task-status` to see full picture
3. Verify plan is still appropriate
4. Update state if priorities changed
