# Task Decomposition Strategy

This reference owns delivery-shape selection during Phase 3. Task cards remain atomic planning and acceptance units; delivery batches remain integration and PR units.

## Default: Vertical Tracer Slices for Behavior Changes

Prefer a narrow, complete behavior path through every relevant layer over a horizontal ticket that changes only one layer.

A valid vertical tracer slice:

- delivers one user-visible or externally observable capability end to end;
- is independently demoable or verifiable through the highest stable public seam;
- fits one fresh agent session and has explicit blocking edges;
- includes its tests, documentation, and governance/domain write-back where applicable;
- leaves the repository in a working state and teaches the next slice something real.

Do not create "all schema", "all backend", "all UI", or "all tests" task groups merely because those files are adjacent. Horizontal foundation tasks are justified only when they create a missing seam, shared contract, test harness, or other prerequisite that later slices genuinely require.

Prefer small prefactoring before a behavior slice when it makes the change safer: make the change easy, then make the easy change. The prefactor must have its own behavior-preserving acceptance command and must not smuggle in the requested feature.

## Non-Behavior Operational Tasks

Vertical slicing applies to tasks that change runtime behavior. A plan may also contain standalone operational tasks such as **Docs**, **Governance**, **Validation**, **Release**, or **Archive** when they cannot honestly be folded into a behavior slice.

Each operational task must name its category, explain why it stands alone, and provide a concrete runnable or observable acceptance check. Do not disguise maintenance or milestone work as user-visible behavior.

## Wide Refactor Exception: Expand-Contract

A wide refactor is one mechanical contract change whose blast radius prevents a normal vertical slice from landing green — for example, renaming a shared schema field or changing a widely consumed type.

Sequence it explicitly:

1. **Expand** — introduce the new form beside the old while preserving compatibility and passing existing validation.
2. **Migrate** — move callers in dependency-aware batches sized by blast radius (package, directory, or service). Every migrate task is blocked by Expand and keeps the old form available.
3. **Contract** — remove the old form only after every caller is migrated and search/validation proves no live dependency remains.

If an individual migration batch cannot remain green, keep the sequence but use a documented integration branch and a final integrate-and-verify task. Green is then promised at that explicit gate, not falsely claimed for each intermediate batch.

## Blocking and Batch Rules

- Add only genuine blockers. A ticket with no required predecessor belongs on the current frontier.
- Dependency order follows deployability and contract ownership, not file-system order.
- Delivery batches may group multiple vertical slices when they form one reviewable/rollback unit; they do not erase per-task acceptance criteria or execution events.
- Each phase still ends with a milestone acceptance task that runs combined validation across all slices and expand-contract steps completed in that phase.
- The task plan must state the delivery shape for every task. Behavior-changing exceptions name their foundation/prefactor, expand, migrate, contract, or explicit integration-gate rationale; operational tasks name their Docs, Governance, Validation, Release, or Archive category and standalone rationale.
