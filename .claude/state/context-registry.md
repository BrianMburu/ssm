# Context Registry

<!--
This file tracks which files are relevant to which tasks.
Helps Claude load only what's needed, saving tokens.

Categories:
- Essential: Always load for this task
- Reference: Load on demand when needed
- Deprecated: Never load (old/superseded files)

Token estimates help plan context budget.
-->

## Global Context

<!-- Files relevant to ALL tasks in this project -->

### Essential (Always Load)
- CLAUDE.md (~500 tokens)
- .claude/state/active.md (~800 tokens)

### Reference (Load on Demand)
- README.md
- package.json / requirements.txt / Cargo.toml

---

## Task: example-task

<!-- Copy this section for each new task -->

### Essential (Always Load)
<!-- Core files for this task -->
- src/example/main.ts (~200 tokens)
- src/example/types.ts (~150 tokens)

**Estimated Essential Context**: ~350 tokens

### Reference (Load on Demand)
<!-- Supporting files, load when specifically needed -->
- docs/example-design.md
- tests/example/*.test.ts

### Deprecated (Never Load)
<!-- Old files that should be ignored -->
- src/example/old-implementation.ts (replaced)

### Notes
<!-- Task-specific context notes -->
- Main logic is in main.ts
- Types are shared across modules

---

## Token Budget Guidelines

| Context Level | Token Budget | When to Use |
|--------------|--------------|-------------|
| Minimal | < 2,000 | Quick fixes, single file changes |
| Standard | 2,000 - 5,000 | Normal feature work |
| Extended | 5,000 - 10,000 | Complex refactoring |
| Maximum | 10,000+ | Major architectural changes |

**Warning Thresholds**:
- 70% context: Consider saving state soon
- 80% context: Recommend /save-state then /clear
- 90% context: Urgent - save immediately

---

## Maintenance

To keep this file useful:
1. Update when starting a new task (`/new-task` does this)
2. Move files to "Deprecated" when they're replaced
3. Add token estimates after loading files
4. Review weekly and clean up completed tasks
