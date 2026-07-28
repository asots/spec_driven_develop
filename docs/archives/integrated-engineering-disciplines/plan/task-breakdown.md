# Task Breakdown

## Overview

- **Mode**: LOCAL_ONLY
- **Total phases**: 3
- **Total tasks**: 5
- **Execution tier**: Tier 0 orchestrator-direct; affected files overlap heavily and parallelism would add merge risk.
- **Source snapshot**: `asots/mattpocock-skills@ed37663cc5fbef691ddfecd080dff42f7e7e350d`

## Confirmed Task Definition

Integrate the reusable disciplines from `diagnosing-bugs`, `tdd`, `code-review`, `domain-modeling`, `grill-with-docs`, and `wayfinder`, plus the vertical-slice and expand-contract rules from `to-tickets`, into the existing TAV/Spec-Driven hierarchy. Preserve current routing, authorization, safety, state ownership, delivery batching, and verification contracts. Do not add automatic commits or external tracker writes.

## Phase 1: TAV Specialist Disciplines

**Goal**: TAV owns hard-bug diagnosis, test-first implementation at planned seams, and separate Standards/Spec review axes.

| ID | Task | Priority | Effort | Depends On | Batch | S.U.P.E.R | Test Expectation | Acceptance Criteria |
|:---|:-----|:---------|:-------|:-----------|:------|:----------|:-----------------|:--------------------|
| T1.1 | Add specialist branches to TAV core and implementation guide | P0 | M | — | TAV-B1 | S,U,P | Docs semantics; verify by targeted fingerprints | Diagnostic loop is red-capable and evidence-first; TDD uses planned public seams; two-axis review supplements machine gates; no automatic commit/external write rule appears |
| T1.2 | Align TAV version, bilingual docs, changelog, state example, and verifier | P0 | M | T1.1 | TAV-B1 | P,E,R | `pwsh scripts/verify.ps1` | Version parity is `3.8.0`; EN/ZH feature descriptions match; semantic fingerprints and all existing checks pass |

## Phase 2: Spec-Driven Planning and Fallback Execution

**Goal**: Spec-Driven owns domain refinement, optional wayfinding, vertical decomposition, and fallback execution/review parity.

| ID | Task | Priority | Effort | Depends On | Batch | S.U.P.E.R | Test Expectation | Acceptance Criteria |
|:---|:-----|:---------|:-------|:-----------|:------|:----------|:-----------------|:--------------------|
| T2.1 | Add canonical domain-modeling, wayfinding, and decomposition references; wire core/analyzer/architect/templates | P0 | L | T1.2 | SPD-B1 | S,U,P,R | Structural + semantic validation | Phase 1 analyzes domain surfaces; conditional gate maps decisions/fog without owning implementation progress; Phase 2 asks one decision at a time with recommendations; Phase 3 defaults to vertical tracer slices and uses expand-contract for wide refactors |
| T2.2 | Align fallback executor, lane reviewer, and review protocol with TAV disciplines | P0 | M | T2.1 | SPD-B1 | U,P,R | Prompt fingerprint checks | Hard bug tasks establish a feedback loop; implementation uses planned seams; reviewer reports Standards and Spec axes separately while rerunning validation; TAV remains task-level authority when installed |

## Phase 3: Documentation, Metadata, and Integrated Validation

**Goal**: Publish one coherent local source state with synchronized docs, version metadata, and cross-repository checks.

| ID | Task | Priority | Effort | Depends On | Batch | S.U.P.E.R | Test Expectation | Acceptance Criteria |
|:---|:-----|:---------|:-------|:-----------|:------|:----------|:-----------------|:--------------------|
| T3.1 | Update Spec-Driven bilingual README, version parity sites, verification fingerprints; run integrated validation and archive | P0 | M | T2.2 | SPD-B2 | P,E,R | Full existing validation + `git diff --check` | Version parity is `1.16.0`; README mirrors describe the new disciplines; both repositories pass their supported checks; workflow artifacts are archived; no commit/push/PR/release occurs |

## Delivery Batches

| Batch | Tasks | Goal | Combined Validation | Depends On |
|:------|:------|:-----|:--------------------|:-----------|
| TAV-B1 | T1.1–T1.2 | One reviewable TAV behavior/version unit | TAV verify + targeted `rg` + diff review | — |
| SPD-B1 | T2.1–T2.2 | One coherent Spec-Driven behavior/prompt unit | Spec verify with TAV path + targeted `rg` | TAV-B1 |
| SPD-B2 | T3.1 | Documentation, metadata, final validation, archive | validate.sh + both verify scripts + diff checks | SPD-B1 |
