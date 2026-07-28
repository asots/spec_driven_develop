# Confirmed Task Definition Template

Use this template for the authoritative Phase 2 artifact at `docs/plan/task-definition.md`. Phase 3 task cards, progress files, and GitHub Issue bodies reference this file rather than restating or silently redefining the approved work.

```markdown
# Task Definition: <Project / Transformation Name>

> **Status**: Confirmed
> **Confirmed on**: YYYY-MM-DD
> **Tracking mode**: GITHUB_FULL | GITHUB_STANDARD | LOCAL_ONLY
> **Workflow run ID**: `spd-YYYYMMDD-<project-slug>-<short-id>`

<!-- Generate the run ID once after Phase 2 confirmation. It is immutable for this workflow attempt and scopes remote resources plus the local GitHub recovery ledger. -->

## Goal
<!-- The user-approved outcome, expressed as observable behavior or project state. -->

## Non-goals
<!-- Explicitly excluded work, including tempting adjacent refactors. -->

## Scope
- **In scope**: modules, boundaries, and user-visible outcomes included in this effort.
- **Out of scope**: modules or outcomes intentionally deferred.

## Acceptance Criteria
<!-- Observable completion criteria. Name commands, tests, or concrete checks where known. -->

## Dependencies
<!-- Required systems, prerequisites, decisions, contracts, access, or parallel work. Use `None` when verified absent. -->

## Compatibility and Constraints
<!-- Backward compatibility, supported runtimes, libraries, security, release, performance, or timeline constraints. -->

## Rollback Boundary
<!-- Smallest safely reversible unit, data/contract consequences, and any required rollback evidence. -->

## Testing Policy
<!-- Required test layers, known harness limits, and explicit no-test exceptions. -->

## Governance and Memory Decision
<!-- Resolved instruction surfaces, durable memory surface, and whether any write-back is expected. -->

## Deferred Ambiguities
<!-- Questions intentionally deferred. Each item states why it does not block this approved scope. -->
```

---

**Authority rule**: Change this document before changing downstream task cards when requirements, acceptance, dependencies, constraints, or rollback boundaries change. A change requiring new user authority or approval returns to Phase 2.
