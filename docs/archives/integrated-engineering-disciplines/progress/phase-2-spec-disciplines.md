# Phase 2: Spec Planning and Fallback Contracts

## Tasks

- [x] T2.1 — Add and wire domain-modeling, conditional wayfinding, and decomposition references.
- [x] T2.2 — Align fallback executor, lane reviewer, and review protocol with the TAV specialist contracts.

## Phase Notes

- Wayfinding is preparation-only and cannot replace `MASTER.md` or implementation Issues.
- Detailed rules are single-sourced in references; prompts contain contracts and pointers only.
- Vertical tracer slices are the default; prefactoring and expand-contract are explicit exceptions.
- The fallback executor establishes hard-bug feedback loops, chooses the highest stable public test seam, and advances test-first work in vertical RED→GREEN slices.
- Machine gates run before separate Standards and Spec review axes; neither axis is collapsed into one score or used to replace configured checks.
- Executor and reviewer commits are closed by default and require explicit user authorization relayed by the orchestrator.

## Phase Completion Checklist

- [x] New references resolve.
- [x] Affected prompts consume the references without duplicating them.
- [x] Cross-repository verify passes.
