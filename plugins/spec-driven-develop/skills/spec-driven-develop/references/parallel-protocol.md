# Parallel Execution Protocol

This protocol defines when and how the orchestrator dispatches sub-agents during development work, and how reviewed results are integrated. Issues are task units; delivery batches are integration and PR units. It applies throughout the implementation, not to a specific phase.

---

## Dispatch Admission (Tiered Execution)

Sub-agent dispatch is an economic decision, not a default. A sub-agent pays a cold-start tax (it re-reads issues, files, and rules you already hold) and an orchestration overhead (worktrees, handoffs, integration). Dispatch only when parallelism gain and context-isolation value exceed that cost.

Choose per delivery batch:

- **Tier 0 — orchestrator-direct (default)**: tasks are S/M effort, touch ≤ 3 files, you already hold the context, or acceptance is machine-verifiable. Execute directly in the current or orchestrator-supplied integration worktree. No sub-agents, no worktrees unless branch/worktree authorization was explicitly granted.
- **Tier 1 — single coder**: L/XL task bundles, heavy exploratory reading, or outputs long enough to pollute your context. Delegate the complete batch to one `task-executor`.
- **Tier 2 — parallel lanes**: only when ALL hold — lane file sets are disjoint, each lane is ≥ L effort, each lane is independently verifiable, there are ≤ 4 lanes, and explicit branch/worktree plus commit authorization is confirmed. Launch one `task-executor` per dependency-ready lane in isolated worktrees. Without both authorizations, use Tier 0 or Tier 1 in the current/integration worktree.

If the platform does not support sub-agents, execute all tasks sequentially yourself (Tier 0).

## Review Admission (Tiered Review)

Apply the cheapest review level that matches the risk:

- **L1 — machine validation (always)**: targeted acceptance checks plus the batch's combined validation.
- **L2 — orchestrator diff review (default)**: after L1, read the integrated diff through separate Standards and Spec axes and verify every Issue's acceptance criteria.
- **L3 — independent reviewer (risk-triggered)**: one `code-reviewer` agent per lane. Mandatory for every Tier 2 lane and for high-risk work: contract/port format changes, complex algorithmic or state-transition logic, or cross-surface semantic invariants. The reviewer reruns L1 commands and reports both axes separately.

Writer model (see `behavioral-rules.md` rules 18-19):

- Each Tier 2 lane gets exactly one `task-executor` (coder), then exactly one `code-reviewer`, in the same worktree on the same lane branch.
- The reviewer verifies the lane's diff against the per-task acceptance criteria and both review axes. Tier 2 admission already requires commit authorization, but the reviewer may create append-only `fix:` commits only when that authorization is explicitly relayed; missing authority is a protocol error returned to the orchestrator, not an uncommitted lane handoff.
- Reviewers never write GitHub Issues/PRs/comments, MASTER.md, drift/adaptive state, or instruction/memory surfaces; their Review Reports return to you.
- You integrate only lanes whose verdict is APPROVED or FIXED; ESCALATE is resolved by you (with the user when needed). You remain the acceptance-verification authority and the single writer for all shared state.

### Two-Axis Review Contract

Run configured machine gates before judgment-based review. They complement rather than replace each other:

1. **Standards** — compare the diff with repository instruction and coding-standard sources. Repository rules override generic guidance. Generic code smells are optional judgment-call heuristics, not hard violations, and should not duplicate issues already enforced by tooling.
2. **Spec** — compare the diff with each task definition and acceptance criteria. Look separately for missing or partial behavior, unauthorized scope expansion, and implementation that appears present but is semantically wrong.

Never collapse the axes into one score. A change can pass Standards and fail Spec, or the reverse. The same reviewer may perform two explicit passes; use separate reviewer agents for the axes only when their independence benefit exceeds cold-start and orchestration cost. Neither axis replaces tests, lint/type checks, compatibility, security, or configuration/IaC validation.

---

## When to Parallelize

At the start of each development phase, read every open Issue in that phase and consult `docs/plan/task-breakdown.md` for delivery batches and parallel lane assignments. Revalidate the planned grouping against current dependencies, file overlap, shared tests, review scope, rollback boundaries, and the dispatch admission criteria above before editing.

- Process delivery batches in dependency order; do not open a PR as soon as one Issue is implemented.
- A batch qualifies for Tier 2 only via the admission criteria, including branch/worktree and commit authorization. If it qualifies, derive dependency-ready execution waves. Launch one `task-executor` per ready lane simultaneously — capped at 4 concurrent lanes per wave (or the platform's lower limit); excess ready lanes queue for the next wave. Integrate each wave, then branch the next wave from the updated integration base. Each lane receives the complete batch context plus its assigned task/Issue subset.
- Tasks that change a shared contract (an interface, schema, or type consumed by more than one lane) run in the earliest wave — wave 0 when possible — so later lanes branch from the updated contract instead of colliding with it at integration.
- Otherwise execute at Tier 0 or Tier 1 — do not force parallelism or split a batch into task-level PRs.

---

## How to Launch Parallel Task Executors

For each parallel lane in the current dependency-ready wave:

1. Prepare the input for each `task-executor` agent:
   - Delivery Batch ID, batch goal, rationale, combined validation, and complete ordered task/Issue set
   - Assigned lane ID plus its task IDs and descriptions from the plan
   - **Tracking mode** (`GITHUB_FULL`, `GITHUB_STANDARD`, or `LOCAL_ONLY`)
   - **GitHub Issue numbers** (GitHub modes) or inline task descriptions (LOCAL_ONLY)
   - Per-task acceptance criteria, test expectations, and explicit no-test rationales, if any
   - **Frozen shared contracts**: the batch's shared-contract list (interfaces, schemas, types crossing lane boundaries), each entry marked `frozen` or `owned` by a named task; a lane must not modify a frozen contract — it reports BLOCKED for coordination instead
   - Per-task memory/governance impact and expected surface updates, if any
   - Relevant source file paths (from `docs/analysis/module-inventory.md`)
   - Coding standards from the orchestrator's dispatch input
   - Current project governance context from the resolved instruction and memory surfaces
   - Summary of completed prerequisite tasks and their outputs
   - The orchestrator's explicit branch/worktree and commit-authorization status; missing or unclear means Tier 2 dispatch is forbidden

2. Launch all ready lane agents **in a single message** (this is how platforms achieve true parallelism). Each agent works in an isolated worktree to prevent file conflicts. Do not launch a downstream lane until its prerequisite changes are integrated.
   - **In GitHub modes**: Use only the orchestrator-resolved lane branch name. The canonical fallback is owned by `references/github-integration.md` and includes the workflow run ID. Lane agents create one accepted atomic commit per task card and never create PRs or use closing keywords. If authorization is missing, do not launch the lane; downgrade the batch to Tier 0/1.
   - **In LOCAL_ONLY mode**: Use worktree isolation if available; otherwise work sequentially

3. When a coder returns DONE, dispatch one `code-reviewer` for the lane (L3 review) with:
   - The lane ID, its assigned task/Issue subset, and the per-task acceptance criteria (the reviewer's checklist)
   - The coder's handoff report
   - The lane branch + worktree path and the lane-level validation commands
   - The orchestrator's explicit commit-authorization status (required for Tier 2; missing means protocol error)

   The reviewer verifies the diff through machine gates plus separate Standards and Spec axes, commits small fixes only when the required authorization was relayed, and returns a Review Report (verdict APPROVED | FIXED | ESCALATE). Missing authorization or any unresolved fix is ESCALATE; resolve it before integrating that lane.

4. When all lanes carry verdict APPROVED or FIXED, consolidate their results:
   - Verify each lane's Review Report and re-run the Standards and Spec passes against the acceptance criteria yourself (L2)
   - **In GitHub modes**: Consolidate lane commits onto the orchestrator-resolved batch integration branch. Its canonical fallback is owned by `references/github-integration.md`; this protocol never reconstructs the name. Resolve conflicts there; there is exactly one integration PR for the batch.
   - **In LOCAL_ONLY mode**: If agents worked in worktrees, merge their changes sequentially, resolving any conflicts
   - Run every task's targeted checks plus the batch's combined validation to verify the integrated changes are coherent
   - Verify each completed Issue's acceptance criteria and record its execution event once. In parallel runs, the orchestrator is the single writer for task records, MASTER.md, and response state.
   - After integration passes, create the batch PR only when separate push and PR authorization is confirmed. Include one `Closes #N` line per fully completed Issue and use `Refs #N` for partial coverage; otherwise report the locally validated integration branch/diff without remote writes.
   - Verify any reported instruction or memory surface updates are consistent and do not create competing sources of truth

---

## Progress Synchronization

After the orchestrator consolidates a delivery batch, invoke `references/adaptive-control.md` "Canonical Storage" and "Controller Activation" once for the integrated results. This protocol adds only the writer boundary: lane reports are reconciled by the orchestrator, native task tools remain session aids, and any instruction or memory update is one orchestrator-owned authorized write after integration.

---

## Merge Risk Mitigation

The `task-breakdown.md` includes merge risk ratings for parallel lanes. Apply these safeguards:
- **Low risk**: Merge freely — lanes touch different files
- **Medium risk**: Merge sequentially, run tests between each merge
- **High risk**: Consider running these tasks sequentially instead of in parallel, or use worktree isolation with careful conflict resolution

---

## Post-Integration Architecture Validation

After the test suite passes on integrated parallel results, perform these architecture-level checks. These go beyond functional correctness to verify structural integrity across lane boundaries.

### Cross-Lane S.U.P.E.R Compliance

Verify that parallel execution did not introduce cross-lane violations:
- **S (Single Purpose)**: No module gained responsibilities from multiple lanes
- **U (Unidirectional Flow)**: No circular dependencies introduced between code touched by different lanes
- **P (Ports)**: Interface contracts at lane boundaries remain intact — if Lane A changed a module's API, Lane B's usage still conforms
- **E (Environment-Appropriate)**: Configuration, paths, lifecycle, persistence, and logging remain valid for every supported runtime touched across lanes
- **R (Replaceable)**: No lane created implicit coupling that makes another lane's modules harder to replace

### Aggregate Execution Events

After consolidating a delivery batch's parallel results, pass every unrecorded lane event to the single orchestrator invocation defined by `references/adaptive-control.md` "Controller Activation" before starting the next delivery batch.
