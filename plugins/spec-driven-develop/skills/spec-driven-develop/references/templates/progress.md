# Progress Document Templates

Templates for the tracking documents generated in Phase 4 (Progress Tracking Documentation). Output to `docs/progress/`. Choose the template that matches the detected tracking mode.

> **FORMAT FREEZE**: `scripts/export-progress.py` parses these files by regular expression. The following patterns are load-bearing ports — change them only together with the exporter:
>
> - Title line `# <Task Name> -- Progress Tracker` (the `--` separator must be ASCII hyphens, never an em-dash)
> - Blockquote fields `> **Started**: ...` / `> **Last Updated**: ...`
> - Phase checklist `- [ ] Phase N: <name> (0/N tasks)`
> - Phase-file task entries `- [ ] **Task N.M**: ...` with `- Priority:`, `- Effort:`, `- Acceptance:` sub-fields

---

## MASTER.md — GitHub Mode (GITHUB_FULL / GITHUB_STANDARD)

Use this template when the tracking mode is `GITHUB_FULL` or `GITHUB_STANDARD`. MASTER.md serves as a lightweight local index pointing to GitHub resources. Actual task status lives in GitHub Issues.

```markdown
# [Task Name] -- Progress Tracker

> **Task**: One-line description
> **Started**: YYYY-MM-DD
> **Last Updated**: YYYY-MM-DD
> **Mode**: GITHUB_FULL | GITHUB_STANDARD
> **Workflow run ID**: `spd-YYYYMMDD-<project-slug>-<short-id>`
> **Repo**: owner/repo

## GitHub Resources
- **Project Board**: https://github.com/users/{user}/projects/{num} _(GITHUB_FULL only)_
- **All Issues for this run**: `gh issue list -R {repo} --label "spec-run:{run-id}" --state all`
- **Open Batch PRs for this run**: `gh pr list -R {repo} --state open --search "head:batch/{run-id}/"`

## References
- [Project Overview](../analysis/project-overview.md)
- [Module Inventory](../analysis/module-inventory.md)
- [Risk Assessment](../analysis/risk-assessment.md)
- [Confirmed Task Definition](../plan/task-definition.md)
- [Task Breakdown](../plan/task-breakdown.md)
- [Dependency Graph](../plan/dependency-graph.md)
- [Milestones](../plan/milestones.md)
- [GitHub Sync Ledger](../plan/github-sync.md)

## Milestones

| Phase | Name | Milestone URL | Open | Closed | Total |
|:------|:-----|:-------------|-----:|-------:|------:|
| 1     |      | https://github.com/{owner}/{repo}/milestone/1 | N | 0 | N |
| 2     |      | https://github.com/{owner}/{repo}/milestone/2 | N | 0 | N |

## Delivery Batches

| Batch | Phase | Issues | Integration Branch | PR | Status |
|:------|:------|:-------|:-------------------|:---|:-------|
| P1-B1 | 1     | #101, #102 | `batch/<run-id>/p1-b1-<slug>` | — | planned |

## Quick Status Commands

```bash
# Phase progress (filter the run-scoped milestone titles)
gh api "repos/{owner}/{repo}/milestones?state=all" --jq '.[] | "\(.title): \(.open_issues) open, \(.closed_issues) closed"'

# Open tasks for a phase
gh issue list -R {repo} --label "spec-run:{run-id}" --milestone "[{run-id}] Phase 1: {name}" --state open --json number,title

# All spec-driven Issues
gh issue list -R {repo} --label "spec-run:{run-id}" --state all --json number,title,state,milestone

# Open delivery batch PRs
gh pr list -R {repo} --state open --search "head:batch/{run-id}/" --json number,title,headRefName,url
```

## Phase Checklist
- [ ] Phase 1: <name> (0/N tasks) — [milestone](https://github.com/{owner}/{repo}/milestone/1)
- [ ] Phase 2: <name> (0/N tasks) — [milestone](https://github.com/{owner}/{repo}/milestone/2)

## Current Status
<!-- Updated by the agent at the start and end of each work session -->
**Active Phase**: Phase N
**Active Delivery Batch**: Pn-Bn / none
**Active Issues**: #NNN, #NNN / none
**Blockers**: None / description
**Adaptive Response**: normal / watch / replan / rescope

## Governance Status
<!-- Updated when project-level agent rules or durable memory change -->
**Shared instruction surface**: `AGENTS.md` / other / unavailable
**Claude Code instruction surface**: `CLAUDE.md` / unavailable
**Other platform rule surfaces**: `.cursor/rules/`, `.windsurf/`, `.clinerules*`, `.codex/`, or none
**Memory surface**: native / existing repo fallback / explicit fallback / unavailable
**Memory fallback path**: none / `docs/memory/` / `<path>`

## Next Steps
<!-- What the agent should do next when resuming in a new conversation -->
1. ...
2. ...

## Recent Session Summaries
<!-- Keep only the latest three summaries; detailed historical evidence stays in the authoritative Issue or phase file. -->
| Date | Session | Summary |
|:-----|:--------|:--------|
|      |         |         |
```

---

## MASTER.md — LOCAL_ONLY Mode

Use this template when the tracking mode is `LOCAL_ONLY`. This is the original full-fidelity progress tracking format.

```markdown
# [Task Name] -- Progress Tracker

> **Task**: One-line description
> **Started**: YYYY-MM-DD
> **Last Updated**: YYYY-MM-DD
> **Mode**: LOCAL_ONLY
> **Workflow run ID**: `spd-YYYYMMDD-<project-slug>-<short-id>`

## References
- [Project Overview](../analysis/project-overview.md)
- [Module Inventory](../analysis/module-inventory.md)
- [Risk Assessment](../analysis/risk-assessment.md)
- [Confirmed Task Definition](../plan/task-definition.md)
- [Task Breakdown](../plan/task-breakdown.md)
- [Dependency Graph](../plan/dependency-graph.md)
- [Milestones](../plan/milestones.md)

## Phase Summary

| Phase | Name | Tasks | Done | Progress |
|:------|:-----|------:|-----:|:---------|
| 1     |      |     N |    0 |          |
| 2     |      |     N |    0 |          |

## Phase Checklist
- [ ] Phase 1: <name> (0/N tasks) — [details](./phase-1-<name>.md)
- [ ] Phase 2: <name> (0/N tasks) — [details](./phase-2-<name>.md)

## Current Status
<!-- Updated by the agent at the start and end of each work session -->
**Active Phase**: Phase N
**Active Task**: Task description
**Blockers**: None / description
**Adaptive Response**: normal / watch / replan / rescope

## Governance Status
<!-- Updated when project-level agent rules or durable memory change -->
**Shared instruction surface**: `AGENTS.md` / other / unavailable
**Claude Code instruction surface**: `CLAUDE.md` / unavailable
**Other platform rule surfaces**: `.cursor/rules/`, `.windsurf/`, `.clinerules*`, `.codex/`, or none
**Memory surface**: native / existing repo fallback / explicit fallback / unavailable
**Memory fallback path**: none / `docs/memory/` / `<path>`

## Next Steps
<!-- What the agent should do next when resuming in a new conversation -->
1. ...
2. ...

## Recent Session Summaries
<!-- Keep only the latest three summaries; detailed historical evidence stays in the authoritative phase file. -->
| Date | Session | Summary |
|:-----|:--------|:--------|
|      |         |         |
```

---

## phase-N-\<name\>.md (Per-Phase Detail File — LOCAL_ONLY mode)

In `LOCAL_ONLY` mode, create one per phase. In GitHub modes, these files are optional — the phase's task list lives in GitHub Issues filtered by milestone.

```markdown
# Phase N: <Phase Name>

**Goal**: What this phase achieves
**Status**: Not Started / In Progress / Complete

## Tasks
- [ ] **Task N.1**: Description
  - Priority: P0
  - Effort: M
  - Delivery Batch: P1-B1
  - Dependencies: None
  - S.U.P.E.R Drivers: S, P
  - Delivery Shape: Vertical tracer slice
  - Affected Files: `src/...`, `tests/...`
  - Test Expectation: Add/update relevant automated tests
  - Governance Impact: Update resolved memory surface if a durable rule emerges
  - Rollback: Revert this task's isolated change without reverting unrelated batch work
  - Acceptance: How to verify this is done
  - Execution Event: as-planned / reworked / replanned / blocked — evidence and unplanned dependencies
  - Notes: _none yet_
- [ ] **Task N.2**: Description
  - Priority: P1
  - Effort: S
  - Delivery Batch: P1-B1
  - Dependencies: Task N.1
  - S.U.P.E.R Drivers: U, E
  - Delivery Shape: Docs standalone task — no runtime behavior change
  - Affected Files: `docs/...`
  - Test Expectation: Not applicable: docs-only; run markdown/static validation
  - Governance Impact: None
  - Rollback: Revert the documentation-only task
  - Acceptance: How to verify this is done
  - Execution Event: as-planned / reworked / replanned / blocked — evidence and unplanned dependencies
  - Notes: _none yet_

## Phase Notes
<!-- Decisions, blockers, context discovered during this phase -->

## Phase Completion Checklist
- [ ] All tasks above are checked off
- [ ] MASTER.md phase count updated
- [ ] MASTER.md "Current Status" updated to next phase
```
