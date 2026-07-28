# Spec-Driven Develop Changelog

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
