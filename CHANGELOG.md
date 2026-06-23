# Changelog

All notable changes to SSM are recorded here. Versioning is semantic
(`MAJOR.MINOR.PATCH`); the canonical version lives in
`.claude-plugin/plugin.json`. Each installed project records its version in
`.claude/.ssm-version` (written by `setup.sh` / `upgrade.sh`).

The labels "v2.1" / "v3" used in older docs were informal generation tags, not
release numbers — this changelog and `plugin.json` supersede them. The
"multi-session v3" generation corresponds to **1.1.0**.

## [Unreleased]

### Planned
- **Orchestration Awareness v1** (opt-in `Execution model: orchestrated`): per-phase
  `Owner:` in `plan.md`, mode-aware posture injection in `session-start`/`stop-hook`,
  and rules that frame delegation as context-positive. Default `solo` stays unchanged.
- **Phase D**: subagent attribution (`agent_id`) and cross-session auto-orchestration.

## [1.1.0] - 2026-06-17

Multi-session integrity, durable design strategy, proactive guards, and a safe
upgrade path. Backward compatible — default (solo) behavior is unchanged.

### Added
- **Design Contract** — a bounded `## Design Contract` section in the `plan.md`
  template (the durable "HOW"). Re-injected into context on every resume by
  `session-start`, re-affirmed on every `/save-state`, treated as binding by
  `continue-task` and the core rule. Fixes implementation-strategy loss across
  save→clear→resume cycles.
- **Heartbeat + locks** — `.claude/state/locks/<session>.heartbeat` (liveness)
  and `<task>.lock` (ownership); a `LastSeen` column in `active-tasks.md`;
  `claim-task` uses 30-min liveness instead of an arbitrary 24h rule.
- **Proactive detection** — `track-changes` warns (never blocks) on wrong-task /
  foreign-live-lock edits; `context-check` flags a live conflicting session each
  prompt. Both debounced and reset on session start.
- **`upgrade.sh`** — refreshes behavior files only (hooks, commands, skills,
  agents, rules, scripts, hook registration, task templates); never touches
  `state/`, task data, `CLAUDE.md`, or `settings.json`. Use this (not `setup.sh`)
  to update SSM in an in-use project. Supports `--dry-run` and `--with-settings`.
- **Per-project version stamp** — `setup.sh` and `upgrade.sh` write
  `.claude/.ssm-version` so a project records which SSM version it runs.
- **Working plugin install** — the plugin manifest now passes
  `claude plugin validate`; `hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` so
  plugin-installed hooks resolve correctly; a new `scripts/bootstrap.sh`
  (invoked on first SessionStart of a plugin install) materializes the
  project-side scaffolding plugins can't ship (state, task templates, rules).
  A `.claude-plugin/marketplace.json` makes the plugin installable via
  `/plugin marketplace add BrianMburu/ssm` + `/plugin install ssm@ssm`; README
  install instructions corrected to the real marketplace flow.

### Changed
- **Session identity** — hooks and commands resolve a stable session id as
  `env CLAUDE_SESSION_ID → hook stdin session_id → "default"`.
- `save-state` now reconciles the edited task against "Current Task" and
  **stops-and-asks** on mismatch before writing any `progress.md`.

### Fixed
- **Cross-terminal session-id collisions** — removed the `$PPID` fallback that
  made two sessions share one state file and silently corrupt task state.
- **Wrong-task progress writes** — the reconciliation guard + proactive nudges
  prevent saving progress to the wrong task.
- **Invalid plugin manifest** — `commands`/`skills`/`agents`/`hooks` paths now
  start with `./`; removed unsupported `rules`/`scripts`/`files` fields.
- **`setup.sh` skipped task templates** — copied with `tasks/*` (a glob that
  silently skips the dotfile `.templates/` dir); now uses `tasks/.`.
- **Shipped example/dev artifacts** — removed the bundled `tasks/session-id-bug`,
  `tasks/unknown`, stale `session-*.md`, and legacy `task-template.md` that
  `setup.sh` was leaking into installs.
- **`uninstall.sh` left residue** — now removes `.ssm-version`, the
  `state/locks/` gitignore line, and `bootstrap.sh`.

## [1.0.0] - prior baseline

- Multi-instance session state, task structure (task/plan/progress/context/
  decisions), context thresholds with compaction blocking, slash commands,
  skills, hooks, and the plugin manifest.
