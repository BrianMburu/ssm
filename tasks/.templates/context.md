# Context: {{TASK_ID}}

**Purpose**: Track files needed for this task and their token costs.
**Goal**: Stay under 70% context (140k tokens) before save+clear.

## Current Session Context

**Loaded this session**: 0 tokens (estimated)
**Target maximum**: 140k tokens (70%)
**Danger zone**: 155k tokens (77.5%)

## Essential Files (Load First)

Files critical for current phase. Load these immediately.

| File | Est. Tokens | Status | Reason |
|------|-------------|--------|--------|
| <!-- src/main/file.ts --> | ~500 | Not loaded | Primary file to modify |
| <!-- src/types/index.ts --> | ~200 | Not loaded | Type definitions |

**Subtotal**: ~700 tokens

## Phase-Specific Files

### Phase 1: Research
| File | Est. Tokens | Load When |
|------|-------------|-----------|
| <!-- Related implementation --> | ~1000 | Understanding patterns |

### Phase 2: Implementation
| File | Est. Tokens | Load When |
|------|-------------|-----------|
| <!-- Files to modify --> | ~X | During implementation |

### Phase 3: Testing
| File | Est. Tokens | Load When |
|------|-------------|-----------|
| <!-- test files --> | ~X | Writing tests |

## Reference Files (Load on Demand)

Only load when specifically needed. Unload after use.

| File | Est. Tokens | Purpose |
|------|-------------|---------|
| <!-- docs/api.md --> | ~500 | API reference |
| <!-- examples/sample.ts --> | ~300 | Pattern reference |

## Do NOT Load

Files to avoid - either irrelevant or already processed.

| File | Reason |
|------|--------|
| node_modules/* | Never load |
| dist/* | Build output |
| <!-- Previously researched files --> | Already processed |

## Token Estimation Guide

Rough formula: **~4 characters = 1 token**

| File Size | Estimated Tokens |
|-----------|-----------------|
| 1 KB | ~250 tokens |
| 4 KB | ~1,000 tokens |
| 10 KB | ~2,500 tokens |
| 40 KB | ~10,000 tokens |

## Context History

Track what was loaded in previous sessions to avoid re-loading.

| Session | Files Loaded | Total Tokens | Notes |
|---------|--------------|--------------|-------|
| {{SESSION_ID}} | Starting | 0 | Initial session |

## Quick Actions

**Check context**: `/context` (built-in command)
**Estimate file**: `wc -c <file>` then divide by 4
**Current status**: Review "Loaded this session" above
