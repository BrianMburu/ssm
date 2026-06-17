# SSM Planner Subagent

Use this agent for isolated planning sessions without committing to implementation.

## Purpose

The planner subagent runs in isolated context to:
- Design implementation approaches
- Evaluate trade-offs between options
- Create detailed step-by-step plans
- Identify risks and dependencies

The plan is returned to the main conversation for approval before implementation begins.

## When to Use

Invoke this subagent when:
- Starting a complex feature that needs architectural thinking
- User asks "how should we approach this?"
- Multiple valid implementation paths exist
- Need to understand dependencies before committing

## How to Invoke

Use the Task tool with `subagent_type: "Plan"`:

```
Task tool parameters:
- subagent_type: "Plan"
- prompt: "Design an implementation plan for adding OAuth2 authentication"
- description: "Plan OAuth2 implementation"
```

## Example Prompts

**Feature planning:**
```
Design an implementation plan for adding real-time notifications.
Consider: WebSocket vs SSE vs polling, scaling implications, fallback strategies.
Return a step-by-step plan with file changes needed.
```

**Refactoring planning:**
```
Plan the migration from Redux to Zustand.
Identify all affected files, migration order, and rollback strategy.
```

**Architecture decisions:**
```
Evaluate three approaches for implementing caching:
1. In-memory (node-cache)
2. Redis
3. File-based

Compare trade-offs and recommend an approach for our scale.
```

## Plan Output Format

Request plans in this format for consistency:

```markdown
## Goal
<One sentence describing what we're achieving>

## Design Contract
<The durable "HOW" — this becomes plan.md's Design Contract, re-injected every
session. Keep it ≤ ~25 lines.>
- Approach: <chosen architecture/strategy and why>
- Conventions & patterns: <naming, layering, libs, error handling>
- Invariants (must NOT break): <data shapes, APIs, ordering>
- Key decisions: <DEC-001: chose X over Y because Z>
- Anti-goals: <what NOT to build>

## Steps
1. [ ] Step one (files: x.ts, y.ts)
2. [ ] Step two (files: z.ts)
...

## Risks
- Risk 1: Mitigation
- Risk 2: Mitigation

## Dependencies
- External: <libraries, services>
- Internal: <other features, data>
```

## Best Practices

1. **Provide context** - Include relevant constraints, tech stack, scale
2. **Ask for options** - "Evaluate 2-3 approaches" gets better analysis
3. **Request trade-offs** - Explicit pros/cons for each option
4. **Set scope** - "Focus on MVP" vs "consider future scale"

## Integration with SSM

After planning:
1. If plan is approved, create task with `/new-task`
2. Task creates full structure including `plan.md` with checkpoints
3. Write the **Design Contract** into `plan.md` — it is re-injected on every
   resume and is the main defense against cross-session strategy drift
4. Steps go into `progress.md` (source of truth)
5. Sync `progress.md` to TodoWrite for UI visibility
6. Update `active.md` with first step as Current Focus

**Important**:
- `progress.md` is the source of truth, not TodoWrite
- `plan.md` includes checkpoint markers for multi-session work
- Large tasks spanning multiple sessions is NORMAL

## Plan vs EnterPlanMode

| Use Case | Tool |
|----------|------|
| Quick exploration of options | Planner subagent |
| Complex feature needing user approval | EnterPlanMode |
| Research before deciding approach | Planner subagent |
| Implementation requiring checkpoint approval | EnterPlanMode |

The planner subagent is lighter-weight - use it for thinking, use EnterPlanMode for formal planning with approval gates.
