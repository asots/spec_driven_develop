# Spec-Driven Develop Changelog

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
