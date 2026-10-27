# Spec-Driven Develop Changelog

## Version 1.30.0 (2026-10-27)

### Decision-recording contract and bundled change classification

- **Added**: Behavioral rule 16 now defines decision-note qualification (costly to reverse, surprising without context, genuine trade-off), the decision-type to note-class mapping, and the task-level versus batch-level recording contract.
- **Added**: `references/change-classification.md` is bundled with the skill; its L0/L1/L2 definitions match TAV's lightweight-L0 workflow and its case table counts only the signals it defines.
- **Changed**: The L2 escalation signals and dual-classification text link to the bundled reference instead of a workspace-level shared file.

## Version 1.29.0 (2026-10-27)

### Review fixes: decision records, untracked files, archive re-entry

- **Fixed**: `task-architect` and `project-analyzer` read decision records with the same lifecycle rules as `task-executor` and TAV. Implemented notes and accepted ADRs are constraints, proposed notes are pending intent, rejected notes are not re-proposed without new evidence, and `.agents/notes/archived/` is skipped. The search names `rg --hidden` only as an example.
- **Fixed**: The Spec axis (`parallel-protocol.md`, `code-reviewer`, `task-executor`) flags implementation that contradicts a recorded decision unless the task card explicitly supersedes it.
- **Fixed**: `task-executor` verification starts from `git status --porcelain` as well as `git diff`, so untracked files are reviewed.
- **Fixed**: Archive re-entry. A run whose first pass left a copy-only snapshot pending remote sync now refreshes its own archive directory and index row; it no longer creates a second archive or a duplicate row. The index's only in-place edit is that run's status changing to `Complete`.
- **Changed**: `scripts/verify.ps1` resolves every quoted section citation, pins each cited behavioral-rule number to its title, and checks that the input-mapping table and TAV's task intake carry the same six fields. It also checks the decision-note contract against a sibling `write-notes-like-deepseek` checkout (`-DshPath`); CI checks that repository out.

## Version 1.28.0 (2026-10-27)

### Optional open-code-review in the Standards axis

- **Added**: When the `ocr` CLI (open-code-review, v1.9.0 or later) is on PATH, the Standards axis uses its delegate mode to select reviewable files, including untracked ones, and their rule groups; otherwise the manual pass applies. This covers the shared review contract in `references/parallel-protocol.md` (so it also applies when the orchestrator reviews directly), `code-reviewer`, and `task-executor`. Detection is a shell `ocr --version` check, not an agent-specific mechanism. Delegate mode calls no LLM and never replaces the Spec axis, machine gates, or security review. `scripts/verify.ps1` fingerprints the new text.

## Version 1.27.0 (2026-10-27)

### Review fixes: task-card context and decision-note lifecycle

- **Fixed**: The GitHub Issue body carries Delivery Shape and Rollback Boundary, and the parallel-protocol dispatch lists give `task-executor` and `code-reviewer` the delivery shape, rollback boundary, tracking mode, and instruction surfaces their contracts require.
- **Fixed**: Rule 16 defines the decision-note lifecycle: a Phase 2 note stays `proposed` until its batch integrates, and Phase 6 resolves leftover proposed notes before cleanup. `task-executor` and the TAV write-back mapping have a decision-note slot.
- **Fixed**: `AGENTS.md` lists `scripts/verify.ps1` next to `scripts/validate.sh`; the README trees no longer list the removed `docs/archives/`; `scripts/verify.ps1` checks the new Issue fields and dispatch lines.

## Version 1.26.0 (2026-10-26)

### Distribution points at the asots fork

- **Changed**: The install scripts, both READMEs, the plugin and marketplace manifests (`homepage`, `repository`, `websiteURL`), and the GitHub Issue/PR footer links point at `asots/spec_driven_develop` instead of the upstream `zhu1090093659/spec_driven_develop`, so remote installs fetch this fork. Author and owner attribution is unchanged.

## Version 1.25.0 (2026-10-26)

### tav skill folder, CI, and decision records in task-executor

- **Changed**: `scripts/verify.ps1` reads tav-workflow from its skills/tav-workflow/ folder (tav 3.16.0+). In CI (`CI=true`) a missing tav-workflow checkout fails the run instead of skipping the cross-repo checks.
- **Added**: A GitHub Actions workflow runs both repositories' self-checks against sibling checkouts.
- **Changed**: The `task-executor` fallback discipline searches decision records before editing, matching tav-workflow's Thinker evidence rule; a task card that contradicts a recorded decision is reported as a blocker.

## Version 1.24.0 (2026-10-26)

### Archive protocol on demand; complementary validators

- **Changed**: The Phase 6 archive procedure moved to `references/archive-protocol.md`; `SKILL.md` keeps the trigger and a pointer (SKILL.md 33.2KB -> 30.2KB). The bundled installer requires the new file.
- **Changed**: `scripts/verify.ps1` drops the checks `scripts/validate.sh` already performs (manifest versions, agent files, the review-context smoke test, archive / GitHub-recovery / S.U.P.E.R-template invariants); run both. It reads the tav handoff section from tav-workflow's references/spec-driven-interop.md (tav 3.15.0+).

## Version 1.23.0 (2026-10-26)

### Shorter trigger description

- **Changed**: The skill `description` drops from 851 to 567 characters. It keeps the two-of-four L2 signal test, the Chinese trigger cues, and the single-module boundary with `tav-workflow`; the phase-by-phase capability list it no longer repeats is in the skill body.

## Version 1.22.0 (2026-10-26)

### Phase 2 decisions routed through rule 16

- **Changed**: Phase 2 domain modeling records qualifying decisions through behavioral rule 16's decision-note channel instead of writing ADRs directly; the `domain-modeling` skill keeps glossary write-back. Without `write-notes-like-deepseek`, such a decision is reported as a pending note candidate.
- **Changed**: Phase 1 analysis reads both ADR directories and `.agents/notes/` decision notes as decision records.

## Version 1.21.0 (2026-09-20)

### Decision-note capture integrated

- **Added**: Behavioral rule 16 routes decision-type knowledge (costly to reverse, genuine trade-off, rejected alternatives) to decision notes through the `write-notes-like-deepseek` skill, which owns the note location, format, verification gate, and archival; without that skill, the decision is reported as a pending note candidate. The note format and gate are not vendored, keeping a single source of truth.
- **Changed**: Phase 5 progress updates and the Phase 6 execution retrospective route decision-type calibrations through the new decision-note path alongside the resolved memory surface.

## Version 1.20.0 (2026-07-29)

### Spec/TAV recovery contract closure

- **Added**: A canonical archived `MASTER.md` tombstone schema with an exact marker, archive pointer, pending-operation semantics, and Phase 6 creation rules.
- **Changed**: Authoritative skill text now distinguishes Spec dispatch tiers and phase numbers from TAV task tiers and phase numbers.
- **Added**: The mirrored handoff contract carries the `spec-tav/v1` identifier for cross-repository compatibility checks.

## Version 1.19.0 (2026-07-28)

### Contract alignment and consistency guards

- **Fixed**: Archive paths now use the canonical collision-safe `docs/archives/<project-name>/<run-id>/` layout across the skill, READMEs, and archive template, including an index state for locally validated runs awaiting remote synchronization.
- **Fixed**: The Spec/TAV handoff now uses the canonical execution-event payload and a mirrored three-layer state-ownership contract.
- **Added**: Phase 2 task definitions now record domain decisions/write-back and S.U.P.E.R priorities explicitly.
- **Added**: GitHub Project fields and items now follow lookup → reuse/create → immediate ledger-write recovery semantics.
- **Changed**: Repeated S.U.P.E.R, adaptive-control, and reviewer-writer definitions were replaced by canonical references while retaining safety and single-writer boundaries.
- **Added**: Automated guards cover archive layout, cross-repo payload/state contracts, template fields, Project recovery semantics, and frontmatter-scoped installer version extraction.

## Version 1.18.0 (2026-07-28)

### Installer and recovery hardening

- **Changed**: Bundled-skill installers use transactional staging and repair incomplete installations.
- **Added**: Workflow run isolation, GitHub synchronization ledger recovery, explicit authority gates, and collision-safe archive/cleanup contracts.
- **Changed**: Planning, progress, governance, executor, and reviewer surfaces were aligned with the hardened recovery model.

Earlier release details remain available in repository history and the versioned feature annotations in the READMEs.
