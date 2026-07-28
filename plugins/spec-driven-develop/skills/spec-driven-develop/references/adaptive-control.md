# Adaptive Control Protocol

Keep execution aligned with reality by reacting to observable evidence. This protocol is a feedback loop, not an effort-scoring system: it does not assign formula-derived drift points, pretend subjective estimates are precise, or use wall-clock time an agent cannot reliably observe.

## Execution Events

After a task is implementation-complete and before it is marked done, capture one compact event:

| Field | Record |
|:------|:-------|
| Outcome | `as-planned`, `reworked`, `replanned`, or `blocked` |
| Rework | Number of Verify → Act returns |
| Plan returns | Number of Act → Think returns |
| Unplanned dependencies | Files, modules, contracts, or prerequisites absent from the task card |
| Focused S.U.P.E.R result | Pass, gap, or regression for only the task's declared S.U.P.E.R drivers |

Use concrete evidence: affected paths, failed checks, changed contracts, and accepted task-card updates. Do not record a global S.U.P.E.R score, an effort delta, `task_drift`, or a cumulative numeric `drift_score`.

## Response Levels

### Normal

The task completed as planned. Record its event and continue.

### Watch

Use when a completed task needed rework or exposed an unplanned dependency but the remaining task cards are still credible.

1. Annotate the next task or active phase with the evidence.
2. Adjust only the affected estimate, dependency, or acceptance note.
3. Continue unless a replan trigger appears.

### Replan

Stop before the next unstarted task when any of these holds:

- A task needed a plan return, split, or contract change that invalidates remaining task cards.
- Two completed tasks expose the same unplanned module or contract boundary.
- Combined batch validation reveals a decomposition or dependency mistake rather than a local implementation failure.

Record the reason, update the analysis only where the evidence changed it, then re-enter Phase 3 for the remaining scope. Preserve completed tasks and their records; replace only unstarted work. Do not silently continue with stale task cards.

### Rescope

Stop and return to Phase 2 when the evidence changes user-approved scope, acceptance criteria, architecture, rollback boundary, or required authority. Attach the recorded events and a concrete recommendation. The user must confirm the changed scope before Phase 3 resumes.

## Canonical Storage

Use one authoritative task record and at most one lightweight progress mirror:

- **GITHUB_FULL / GITHUB_STANDARD**: a structured event comment on the task Issue is authoritative. Before Phase 5 begins, explicit GitHub tracker-write authorization must include Issue comments; without it, stop as `awaiting tracker-write authorization` or return to Phase 2 for a user-approved mode change. Do not silently substitute `MASTER.md` or conversation memory as the event record. `MASTER.md` mirrors only the active phase, delivery batch, blocker, and current response level; do not maintain Milestone YAML drift state.
- **LOCAL_ONLY**: the task's entry in the phase file is authoritative. `MASTER.md` mirrors phase counts, current task, blocker, and current response level.
- **Native task tools** are optional session aids, not durable state.

An event may use this compact format:

```markdown
## Execution Event

- Outcome: as-planned | reworked | replanned | blocked
- Evidence: <command result, changed contract, or affected path>
- Rework / plan returns: <n> / <n>
- Unplanned dependencies: none | <items>
- Focused S.U.P.E.R: <drivers and pass/gap/regression>
- Response: normal | watch | replan | rescope
```

## Controller Activation

At session start, read `MASTER.md` and the active authoritative task records. If the recorded response is `replan` or `rescope`, resolve it before starting new work.

After sequential task completion or delivery-batch integration:

1. Collect each completed task's execution event.
2. Have the orchestrator write each event once to its authoritative record; lane agents only return their signals.
3. Update the lightweight MASTER.md mirror once for the active phase or batch.
4. Apply the highest response level supported by the evidence before work starts on the next unstarted task.

## Workflow Integration

| Workflow phase | Adaptive-control responsibility |
|:---------------|:--------------------------------|
| Phase 3 | Make task dependencies, acceptance criteria, and S.U.P.E.R drivers explicit; do not initialize numeric thresholds. |
| Phase 4 | Record the authoritative task surface and lightweight progress mirror. |
| Phase 5 | Record execution events and apply normal, watch, replan, or rescope before the next task. |
| Phase 6 | Distill only recurring, evidence-backed calibration rules from multiple completed tasks. |
