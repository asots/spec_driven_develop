# Archive Templates

Templates for Phase 6 (Archive). Output to `docs/archives/`.

---

## docs/archives/README.md (Archive Index)

```markdown
# Project Archives

This directory contains archived artifacts from completed Spec-Driven Develop workflows. Each subdirectory represents one development project, preserving its full analysis, plan, and progress history for future reference.

| Project | Description | Period | Mode | Run ID | Progress |
|:--------|:------------|:-------|:-----|:-------|:---------|
| [<project-name>](./<project-name>-<run-id>/progress/MASTER.md) | One-line description | YYYY-MM-DD — YYYY-MM-DD | GITHUB_FULL | `<run-id>` | Complete |
```

When updating this file, append new rows to the table. Do not remove existing entries. In GitHub modes, include the GitHub Project URL in the Description field for easy reference.

---

## Archive Directory Structure

```
docs/archives/<project-name>/<run-id>/
├── analysis/
│   ├── project-overview.md
│   ├── module-inventory.md
│   └── risk-assessment.md
├── plan/
│   ├── task-definition.md
│   ├── task-breakdown.md
│   ├── dependency-graph.md
│   ├── milestones.md
│   └── github-sync.md         # GitHub modes, when created
├── progress/
│   ├── MASTER.md
│   ├── phase-1-<short-name>.md
│   └── ...
└── governance/
    ├── surface-resolution.md  # Export from MASTER.md Governance Status
    ├── AGENTS.md              # if resolved and file-backed
    ├── CLAUDE.md              # if resolved and file-backed
    └── memory-surface.md      # export note or fallback snapshot, if available
```

Use a collision-safe `<project-name>-<run-id>` directory and never merge into an existing archive. Before source cleanup, verify required artifacts, relative links, and source-to-archive file counts. Archive governance surfaces as snapshots or export notes only. Keep active instruction and memory surfaces in place after archiving. If memory is native and cannot be exported, record its platform/name and the key decisions that were written there.
