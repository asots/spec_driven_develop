# GitHub Integration Protocol

This document defines how the Spec-Driven Develop workflow integrates with GitHub Issues, Milestones, Labels, Projects, and Pull Requests for task tracking and execution.

---

## Operating Modes

The workflow reports detected capabilities via a pre-flight check. Phase 2 records the user-confirmed tracking mode; capability detection never silently changes that selection.

| Mode | Requirements | Capabilities |
|:-----|:------------|:-------------|
| **GITHUB_FULL** | `gh` CLI + auth + `project` scope | Remote task tracker: Issues + Milestones + Labels + Project board |
| **GITHUB_STANDARD** | `gh` CLI + auth + `repo` scope | Remote task tracker: Issues + Milestones + Labels (no board) |
| **LOCAL_ONLY** | None | Local task tracker: plan and phase files (no remote tracker) |

Tracking modes do not grant or describe branch/worktree creation, commits, pushes, pull requests, or tracker writes. Those are independent authority gates below; LOCAL_ONLY may still use an authorized local branch or worktree.

---

## Authority Gates

Detection and read-only inspection do not authorize writes. Before running a mutating command, confirm that the user's authorization explicitly names its operation class:

| Operation class | Examples | Required authority |
|:----------------|:---------|:-------------------|
| Local branch/worktree changes | `git branch`, `git switch -c`, `git worktree add/remove` | Branch/worktree authorization |
| Local commits | `git add`, `git commit` | Commit authorization; one accepted task card per commit |
| Remote branch writes | `git push` | Push authorization |
| Pull-request writes | `gh pr create/edit/comment/merge/close` | PR authorization |
| Tracker writes | Issue, Milestone, Label, Project creation/edit/comment/close | GitHub tracker-write authorization |

One user response may authorize several named classes together, but never infer one class from another or from the detected tracking mode, an existing branch, an Issue, or general approval to implement. Commit authorization does not authorize branch creation, push, PR creation, or tracker writes. Phase-boundary confirmation is not write authorization unless it names the operations. Tier 2 requires branch/worktree and commit authorization before dispatch because lane integration is commit-based; without both, use Tier 0 or Tier 1 in the current/integration worktree. Creating a batch PR requires commit, push, and PR authorization; tracker comments remain separately gated. Because GitHub-mode execution events are authoritative Issue comments, Phase 5 cannot begin in a GitHub mode until tracker-write authorization explicitly includes Issue comments; otherwise pause for that authorization or obtain the user's approval to switch to LOCAL_ONLY before execution.

---

## Run Isolation and Recovery

Every GitHub-backed workflow attempt has one immutable `RUN_ID` from the confirmed task definition, for example `spd-20260728-api-migration-a1b2`. Before the first tracker write, create `docs/plan/github-sync.md` from `references/templates/github-sync.md` and record its `prepared` state. This ledger is an identity/recovery aid, not a second progress authority.

Use all of these markers together:

- Run label: `spec-run:<RUN_ID>` on every task Issue.
- Issue marker: `<!-- spec-run:<RUN_ID>; task:<TASK_ID> -->` in every Issue body.
- Milestone title: `[<RUN_ID>] Phase N: <name>`.
- Project title: `Spec: <project-name> [<RUN_ID>]`.
- Integration branch prefix: `batch/<RUN_ID>/`.

For each remote resource, first query candidates scoped by the run marker, then verify the exact marker/title, reuse an exact match, or create exactly one resource. Immediately write the resource number, URL, and state to the ledger before attempting the next resource. On interruption, resume from the ledger and re-query remote state; never create a second resource merely because the conversation lost context. Keep generic `priority:*`, `size:*`, `phase:*`, `lane:*`, and `spec-driven` labels reusable across runs, but never use them alone to identify a run.

Never copy secrets, tokens, cookies, authorization headers, connection strings, private user data, or full sensitive logs into an Issue body, comment, Project field, or the recovery ledger. Store a compact redacted evidence summary and a local evidence pointer instead.

---

## Pre-flight Check

Run this check at the end of Phase 1 (after analysis, before proceeding to Phase 2). Report the detected mode to the user.

```bash
# Step 1: gh CLI exists?
gh --version > /dev/null 2>&1 || { echo "LOCAL_ONLY"; exit; }

# Step 2: Authenticated?
gh auth status > /dev/null 2>&1 || { echo "LOCAL_ONLY"; exit; }

# Step 3: GitHub remote exists?
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null) || { echo "LOCAL_ONLY"; exit; }

# Step 4: Can access issues?
gh issue list --repo "$REPO" --limit 1 > /dev/null 2>&1 || { echo "LOCAL_ONLY"; exit; }

# Step 5: Can access projects?
gh project list --limit 1 > /dev/null 2>&1 && echo "GITHUB_FULL" || echo "GITHUB_STANDARD"
```

If the detected mode differs from the user's preference, inform them and explain what's missing (e.g., "Project board requires the `project` scope. Run `gh auth refresh -s project` to enable it.").

---

## Resource Mapping

```
Spec-Driven-Develop Run  →  GitHub Project (board)     [GITHUB_FULL only]
├── Run marker            →  Label "spec-run:<RUN_ID>"
├── Phase N               →  Milestone "[<RUN_ID>] Phase N: <name>"
│   ├── Task N.1          →  Issue with structured body
│   │   ├── Priority P0   →  Label "priority:P0"
│   │   ├── Size M        →  Label "size:M"
│   │   └── Lane A        →  Label "lane:A"
│   └── Task N.2          →  Issue with structured body
└── Delivery Batch B1     →  integration branch + one PR
    ├── Lane work         →  isolated worktree/branch + commits (no PR)
    ├── Task Issues       →  atomic acceptance + execution-event records
    └── Batch PR          →  one `Closes #N` line per completed Issue
```

Issue and PR cardinality are intentionally different. Keep one Issue per task for planning and execution events, then group related Issues into the smallest coherent set of phase-local delivery batches. Default to one reviewable batch PR per phase; do not create a PR merely because one Issue is implemented.

---

## Label Scheme

Create these labels before creating Issues. Use `--force` for idempotency.

```bash
REPO="owner/repo"

# Priority labels
gh label create "priority:P0" --color "d73a4a" --description "Critical — must do first" --repo "$REPO" --force
gh label create "priority:P1" --color "e4e669" --description "Important — do soon" --repo "$REPO" --force
gh label create "priority:P2" --color "0e8a16" --description "Nice to have" --repo "$REPO" --force

# Relative scope labels (not time estimates)
gh label create "size:S" --color "c5def5" --description "Localized, one clear boundary" --repo "$REPO" --force
gh label create "size:M" --color "bfd4f2" --description "One independently verifiable behavior slice" --repo "$REPO" --force
gh label create "size:L" --color "d4c5f9" --description "Recoverable multi-step task card" --repo "$REPO" --force
gh label create "size:XL" --color "f9d0c4" --description "Delivery-batch scope; split before task execution" --repo "$REPO" --force

# Spec-driven workflow label
gh label create "spec-driven" --color "1d76db" --description "Managed by Spec-Driven Develop workflow" --repo "$REPO" --force

# Per-run label (the ledger records the exact run ID before this write)
gh label create "spec-run:$RUN_ID" --color "5319e7" --description "Spec-Driven workflow run $RUN_ID" --repo "$REPO" --force
```

Phase labels are created dynamically based on the actual phase names:
```bash
gh label create "phase:1" --color "ededed" --description "Phase 1: <name>" --repo "$REPO" --force
```

Lane labels are created dynamically based on parallel lane assignments:
```bash
gh label create "lane:A" --color "fef2c0" --description "Parallel lane A" --repo "$REPO" --force
```

---

## Milestone Creation

`gh` has no native `milestone create` subcommand. Use the REST API. First list milestones in every state and reuse only an exact run-scoped title; otherwise create one and immediately record its number and URL in `github-sync.md`:

```bash
gh api repos/{owner}/{repo}/milestones \
  -f title="[$RUN_ID] Phase 1: Foundation" \
  -f description="Phase 1 goal description" \
  -f state="open"
```

To list milestones in every state: `gh api "repos/{owner}/{repo}/milestones?state=all" --jq '.[].title'`

---

## Issue Body Template

Every task Issue uses this structured body format:

```markdown
## Task: {task_id} — {task_name}

**Workflow Run ID**: `{run_id}`
**Phase**: {phase_number} — {phase_name}
**Priority**: {priority} | **Size**: {size} | **Lane**: {lane}
**Delivery Batch**: {batch_id}
**S.U.P.E.R Drivers**: {principles}
**Test Expectation**: {required_tests_or_explicit_no_test_rationale}
**Memory/Governance Impact**: {memory_or_governance_update_expectation}

### Description
{task_description}

### Acceptance Criteria
- [ ] {criterion_1}
- [ ] {criterion_2}
- [ ] Passes S.U.P.E.R Quick Check for: {principles}
- [ ] Satisfies test expectation: {required_tests_or_explicit_no_test_rationale}
- [ ] Updates the resolved memory or instruction surfaces if durable project knowledge or agent instructions changed

### Affected Files
- `{file_path_1}`
- `{file_path_2}`

### Dependencies
- Depends on: {dependency_issue_refs or "None"}

---
<!-- spec-run:{run_id}; task:{task_id} -->
_Managed by [Spec-Driven Develop](https://github.com/zhu1090093659/spec_driven_develop) workflow_
```

Before creating an Issue, list candidates with `--label "spec-run:$RUN_ID" --state all`, inspect any same task ID/body marker, and reuse only the exact `<!-- spec-run:$RUN_ID; task:$TASK_ID -->` match. Create an Issue only when no such match exists:
```bash
gh issue create \
  --repo "$REPO" \
  --title "[T{task_id}] {task_name}" \
  --body "$ISSUE_BODY" \
  --label "spec-driven,spec-run:$RUN_ID,priority:{p},size:{s},phase:{n},lane:{lane}" \
  --milestone "[$RUN_ID] Phase {n}: {phase_name}"
```

Add a 1-second delay between Issue creations to avoid secondary rate limits.

---

## Project Board Setup (GITHUB_FULL only)

### Create Project and Link to Repo

```bash
OWNER="@me"
PROJECT_TITLE="Spec: {project_name} [$RUN_ID]"

# Lookup -> verify uniqueness -> reuse/create -> immediate ledger write.
PROJECT_MATCH_COUNT=$(gh project list --owner "$OWNER" --limit 100 --format json \
  --jq ".projects | map(select(.title == \"$PROJECT_TITLE\")) | length")
if [ "$PROJECT_MATCH_COUNT" -gt 1 ]; then
  echo "Blocked: multiple exact project-title matches for $PROJECT_TITLE" >&2
  exit 1
elif [ "$PROJECT_MATCH_COUNT" -eq 1 ]; then
  PROJECT_NUM=$(gh project list --owner "$OWNER" --limit 100 --format json \
    --jq ".projects[] | select(.title == \"$PROJECT_TITLE\") | .number")
else
  PROJECT_NUM=$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json --jq '.number')
fi
PROJECT_JSON=$(gh project view "$PROJECT_NUM" --owner "$OWNER" --format json)
# Before the next remote write, record PROJECT_NUM plus PROJECT_JSON id/url in github-sync.md.

# Link to repository
gh project link "$PROJECT_NUM" --owner "$OWNER" --repo "$REPO"
```

### Create Custom Fields

For each planned field, perform exact lookup → contract check → reuse/create → immediate ledger write. An exact-name field with the wrong data type or option set is a blocking contract conflict; do not create a duplicate with the same name.

```bash
OWNER="@me"
FIELD_NAME="Priority"
FIELD_TYPE="SINGLE_SELECT"
FIELD_OPTIONS="P0,P1,P2"

FIELD_MATCH_COUNT=$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --limit 100 --format json \
  --jq ".fields | map(select(.name == \"$FIELD_NAME\")) | length")
if [ "$FIELD_MATCH_COUNT" -gt 1 ]; then
  echo "Blocked: multiple exact field-name matches for $FIELD_NAME" >&2
  exit 1
elif [ "$FIELD_MATCH_COUNT" -eq 1 ]; then
  FIELD_JSON=$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --limit 100 --format json \
    --jq ".fields[] | select(.name == \"$FIELD_NAME\")")
  # Verify FIELD_JSON dataType/options match the confirmed plan before reuse.
else
  FIELD_JSON=$(gh project field-create "$PROJECT_NUM" --owner "$OWNER" \
    --name "$FIELD_NAME" --data-type "$FIELD_TYPE" \
    --single-select-options "$FIELD_OPTIONS" --format json)
fi
# Before creating or looking up the next field, record FIELD_JSON id, parent project ID,
# lookup evidence, and reused/created state in github-sync.md.
```

Repeat the same protocol for `Size` (`S,M,L,XL`) and `Phase` (options generated from the confirmed plan, never a hard-coded phase count).

### Add Issues to Project

Use the Issue URL/content ID as the stable identity. Never call `item-add` until an exact lookup confirms that the Issue is absent from the Project.

```bash
ITEM_MATCH_COUNT=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --limit 100 --format json \
  --jq ".items | map(select(.content.url == \"$ISSUE_URL\")) | length")
if [ "$ITEM_MATCH_COUNT" -gt 1 ]; then
  echo "Blocked: Issue appears more than once in the Project: $ISSUE_URL" >&2
  exit 1
elif [ "$ITEM_MATCH_COUNT" -eq 1 ]; then
  ITEM_JSON=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --limit 100 --format json \
    --jq ".items[] | select(.content.url == \"$ISSUE_URL\")")
else
  ITEM_JSON=$(gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$ISSUE_URL" --format json)
fi
# Before processing the next Issue, record ITEM_JSON id, the Issue content ID/URL,
# lookup evidence, and reused/created state in github-sync.md.
```

Setting custom field values on items requires GraphQL node IDs. Retrieve them with:
```bash
# Get project ID
PROJECT_ID=$(gh project view "$PROJECT_NUM" --owner "$OWNER" --format json | jq -r '.id')

# Get field IDs
gh project field-list "$PROJECT_NUM" --owner "$OWNER" --format json | jq '.fields[] | {name: .name, id: .id}'

# Get item IDs
gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json | jq '.items[] | {title: .title, id: .id}'
```

Then set field values:
```bash
gh project item-edit \
  --id "$ITEM_ID" \
  --field-id "$FIELD_ID" \
  --project-id "$PROJECT_ID" \
  --single-select-option-id "$OPTION_ID"
```

Field or item identity lookup/create failures are blocking because recovery would otherwise be ambiguous. After every field and item identity is recorded, a failure to set a custom field value may be downgraded to a warning only when the Issue Labels already carry the same priority, size, and phase values; record the failed command and evidence in `github-sync.md` before continuing.

---

## Delivery Batch Execution Workflow (worktree + PR)

The orchestrator owns batch boundaries, integration state, execution-event responses, and PR creation. Task executors implement complete batches or assigned lanes; they do not create task-level PRs.

### 1. Review the Complete Phase Issue Set

Before editing, list all open Issues in the active phase, then read each Issue's body and comments. Compare dependencies, affected files, shared contracts/tests, release target, review ownership, and rollback risk.

```bash
gh issue list --repo "$REPO" --label "spec-run:$RUN_ID" --milestone "[$RUN_ID] Phase {n}: {phase_name}" --state open --json number,title,labels
gh issue view {issue_number} --repo "$REPO" --json number,title,body,comments,labels,milestone
```

Use these rules to confirm or revise delivery batches:

1. Keep batches within one Phase/Milestone by default.
2. Prefer one coherent batch for Issues that share an architecture invariant, API/data contract, file hotspot, test fixture, or release target.
3. Keep dependency order executable inside the batch; serialize batches when one depends on another.
4. Default to one reviewable batch PR per phase. Split only for a documented reviewability, independent release/rollback, ownership, high-risk isolation, hard dependency, or repository/user policy boundary.
5. Do not split mechanically by Issue count. A single-Issue batch requires an explicit rationale unless it is the only Issue in the phase.
6. Reconsider and document a split when the expected integrated diff exceeds roughly 800 changed lines or 15 files; these are reviewability signals, not automatic partitioning rules.

`docs/plan/task-breakdown.md` is the planning authority for Task → Issue → Delivery Batch mapping. Mirror a changed batch in the affected Issue's structured `**Delivery Batch**` field with `gh issue edit --body-file <updated-body-file>` while preserving the rest of the body and its run marker, then comment with the reason when authorized. Immediately update the matching ledger row; MASTER.md carries only the active batch and status summary, not a second task-by-task mapping.

### 2. Create the Batch Integration Branch and Worktrees When Authorized

Only create branches or worktrees when branch/worktree authorization is explicit. Otherwise keep Tier 0/1 work in the current worktree. When authorized, follow the repository's branch convention; if none exists, use:

- Integration branch: `batch/{run_id}/{batch_id}-{slug}`
- Optional lane branch: `work/{run_id}/{batch_id}-{lane_id}-{slug}`

For a one-lane batch, work directly in one isolated worktree on the integration branch. For a genuinely parallel batch, first confirm both branch/worktree and commit authorization, then execute dependency-ready lanes in waves. Create each wave's lane worktrees from the current integration base; integrate prerequisite commits before branching downstream waves. Every lane receives the complete batch context and its assigned Issue subset.

If the platform provides a native worktree tool, use it according to that platform's documentation instead of manual worktree management.

### 3. Implement, Verify, and Commit Only When Authorized

Follow each Issue's acceptance criteria, test expectation, and memory/governance impact. Read the resolved instruction and memory surfaces before editing. Run one TAV cycle per task card and commit only after that card's acceptance checks pass. Stage only the paths belonging to that card, create one atomic commit that references exactly that task/Issue without closing it, then repeat for the next card:

```bash
git add -- {task_specific_paths}
git commit -m "feat({scope}): {task_description} (refs #{issue_number})"
```

Without commit authorization, Tier 0/1 may return a verified uncommitted integration/current worktree; Tier 2 must not start. Tier 2 lane agents return one accepted commit per task card plus branch references to the orchestrator. They must not run `gh pr create`, add `Closes #N`, write Issue execution events, or race to edit MASTER.md.

### 4. Integrate and Validate the Complete Batch

For Tier 2, the orchestrator consolidates lane commits onto the batch integration branch and resolves overlaps. For Tier 0/1 without commit authorization, the verified diff already lives in the current/integration worktree and no lane consolidation occurs. In either case, run:

- Every included Issue's targeted tests and acceptance checks
- The batch's combined build/test/smoke validation
- The post-integration S.U.P.E.R architecture checks from `parallel-protocol.md`
- Per-Issue execution-event collection, recorded once by the orchestrator

If an Issue is only partially covered, leave it open and use `Refs #N`; do not include a closing keyword until all acceptance criteria pass.

### 5. Push and Create One Batch PR When Separately Authorized

Run this step only when commit, push, and PR authorization are all explicit. Push only the integrated batch branch, then create one PR for all completed Issues in the batch. If either remote-write authorization is absent, stop after local integration validation and report the ready branch/diff without pushing or creating a PR.

```bash
BATCH_BRANCH="{resolved_batch_branch}"
git push -u origin "$BATCH_BRANCH"

gh pr create \
  --repo "$REPO" \
  --title "[Batch {batch_id}] {batch_name}" \
  --body "$(cat <<'EOF'
## Batch Rationale
{why_these_issues_are_one_coherent_review_and_rollback_unit}

## Included Issues
Closes #{issue_1}
Closes #{issue_2}
Refs #{partially_covered_issue_if_any}

| Issue | Task | Acceptance | Targeted Validation |
|:------|:-----|:-----------|:--------------------|
| #{issue_1} | {task_1} | complete | {tests_1} |
| #{issue_2} | {task_2} | complete | {tests_2} |

## Changes
- {change_1}
- {change_2}

## Aggregate Validation
- {combined_test_commands_and_results}

## S.U.P.E.R Review
- [x] Batch passes the post-integration S.U.P.E.R checks for: {principles}

## Risk and Rollback
- Risk: {risk_summary}
- Rollback: {rollback_plan}

## Project Governance
- Instruction surfaces: updated / unchanged (list paths or native surfaces)
- Memory surface: updated / unchanged / unavailable / fallback used

---
_Part of [Spec-Driven Develop](https://github.com/zhu1090093659/spec_driven_develop) workflow_
EOF
)"
```

Add one standalone `Closes #N` line for every fully completed Issue. This lets one merged PR close the whole delivery batch while preserving Issue-level history.

### 6. Synchronize In-Review State and Comment on Issues

Immediately after the PR is created:

1. Update the delivery batch row and Current Status in MASTER.md plus the matching ledger row with the PR number and `in review`.
2. Keep each partially covered Issue open with the PR number, `partial`, and its remaining acceptance work.
3. When GitHub tracker-write authorization includes Issue comments, comment on included Issues using completion-accurate language. Otherwise record the skipped external synchronization in MASTER.md and rely on the authorized PR's Issue links/closing keywords:

```bash
# Fully completed and awaiting merge
gh issue comment {completed_issue} --repo "$REPO" --body "Fully implemented in delivery batch {batch_id}; integration PR: #{pr_number}. Pending merge."

# Referenced but not complete
gh issue comment {partial_issue} --repo "$REPO" --body "Partially covered by delivery batch {batch_id}; integration PR: #{pr_number}. This Issue remains open. Outstanding: {remaining_acceptance_work}."
```

The local MASTER.md synchronization is required before yielding the session so resume logic cannot mistake an open batch PR for unstarted work or create a duplicate PR. The in-review status comments above are optional when separately authorized; this does not relax the Phase 5 requirement for authorized structured execution-event comments on completed task Issues.

### 7. Cleanup

After the batch PR is merged, remove its integration and lane worktrees/branches only with the required cleanup authorization and according to repository policy. Do not clean a lane before the orchestrator has integrated its commits.

---

## Reading Progress from GitHub

New-session continuity protocol (when MASTER.md indicates a GitHub mode):

```bash
REPO="owner/repo"

# Get milestones in every state, then retain only exact titles prefixed with "[$RUN_ID]"
gh api "repos/{owner}/{repo}/milestones?state=all" --jq '.[] | "\(.title): \(.open_issues) open, \(.closed_issues) closed"'

# Get open tasks for a specific phase
gh issue list --repo "$REPO" --label "spec-run:$RUN_ID" --milestone "[$RUN_ID] Phase 1: Foundation" --state open --json number,title

# Get closed tasks for a specific phase
gh issue list --repo "$REPO" --label "spec-run:$RUN_ID" --milestone "[$RUN_ID] Phase 1: Foundation" --state closed --json number,title

# Get all Issues for this run
gh issue list --repo "$REPO" --label "spec-run:$RUN_ID" --state all --json number,title,state,milestone

# Get open batch PRs
gh pr list --repo "$REPO" --state open --search "head:batch/$RUN_ID/" --json number,title,headRefName,url
```

---

## Closing Issues

Issues are closed automatically when their delivery batch PR is merged. The PR body contains one `Closes #N` line per fully completed Issue, so one PR may close several Issues. Do not create single-Issue PRs by default, and do NOT close Issues manually unless the task is cancelled or deferred. Partial coverage uses `Refs #N` and leaves the Issue open.

To defer a task:
```bash
gh issue close {issue_number} --repo "$REPO" --reason "not planned" --comment "Deferred: {reason}"
```
