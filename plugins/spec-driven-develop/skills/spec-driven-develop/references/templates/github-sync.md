# GitHub Sync Ledger Template

Use this Phase 3 template at `docs/plan/github-sync.md` before the first authorized GitHub write. It is a recovery ledger for remote resource identities only; it never replaces Issues, phase files, or `MASTER.md` as progress authorities.

```markdown
# GitHub Sync Ledger: <Project Name>

> **Workflow run ID**: `spd-YYYYMMDD-<project-slug>-<short-id>`
> **Tracking mode**: GITHUB_FULL | GITHUB_STANDARD
> **Repository**: `owner/repo`
> **Sync state**: prepared | awaiting_authorization | syncing | blocked | complete
> **Last updated**: YYYY-MM-DDTHH:MM:SSZ
> **Blocker**: none | missing tracker-write authorization | failed operation and evidence
> **Next remote operation**: exact idempotent lookup or write to resume

## Recovery Rules
- Reuse a resource only when its run ID marker matches this ledger.
- Create one remote resource at a time, then immediately record its stable ID and URL below.
- Never infer completion from this ledger; read Issues, milestones, PRs, and `MASTER.md` for current progress.
- `prepared` means planned locally, not created remotely. Use `complete` only after every in-scope identity below has a stable ID/URL or an explicit not-applicable value.

## Run Marker
- Label: `spec-run:<run-id>`
- Issue body marker: `<!-- spec-run:<run-id>; task:<task-id> -->`
- Milestone title prefix: `[<run-id>]`
- Project title suffix: `[<run-id>]`
- Branch prefix: `batch/<run-id>/`

## Milestones
| Phase | Title | Number | URL | State |
|:------|:------|:-------|:----|:------|
| 1 | `[<run-id>] Phase 1: <name>` | | | planned |

## Labels
| Name | ID/Node ID | URL or Lookup Evidence | State |
|:-----|:-----------|:-----------------------|:------|
| `spec-run:<run-id>` | | | planned |

## Issues
| Task ID | Issue | URL | Milestone | Delivery Batch | State |
|:--------|:------|:----|:----------|:---------------|:------|
| T1.1 | #TBD | | Phase 1 | P1-B1 | planned |

## Project Board (GITHUB_FULL only)
| Project | Number | URL | State |
|:--------|:-------|:----|:------|
| `Spec: <project> [<run-id>]` | | | planned |

## Project Fields and Items (GITHUB_FULL only)
| Resource | Stable ID | Parent/Content ID | Lookup Evidence | State |
|:---------|:----------|:------------------|:----------------|:------|
| Field: `<name>` | | | | planned |
| Item: Task T1.1 | | Issue #TBD | | planned |

## Batch Branches and PRs
| Batch | Branch | PR | URL | State |
|:------|:-------|:---|:----|:------|
| P1-B1 | `batch/<run-id>/p1-b1-<slug>` | #TBD | | planned |
```
