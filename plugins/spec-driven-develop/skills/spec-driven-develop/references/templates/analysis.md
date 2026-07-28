# Analysis Document Templates

Templates for the three documents generated in Phase 1 (Deep Project Analysis). Output to `docs/analysis/`. These documents serve dual purpose: they feed into Phase 2 (Intent Refinement & Confirmation) for grounded user discussion, and into Phase 3 (Task Decomposition) for planning.

---

## project-overview.md

```markdown
# Project Overview

## Preliminary Direction
<!-- One-sentence summary of the intended transformation direction from Phase 0. This will be refined into a confirmed task definition in Phase 2 after the user reviews this analysis. -->

## Current Architecture
<!-- High-level architecture diagram (Mermaid) and description -->

## Technology Stack
| Layer        | Current          | Target           |
|:-------------|:-----------------|:-----------------|
| Language     |                  |                  |
| Framework    |                  |                  |
| Build Tool   |                  |                  |
| Package Mgr  |                  |                  |
| Database     |                  |                  |
| Deployment   |                  |                  |

## Entry Points
<!-- List of main entry points: CLI commands, API endpoints, UI routes, etc. -->

## Build & Run
<!-- How to build, test, and run the project currently -->

## Testing Baseline
<!-- Existing test frameworks, test commands, coverage gaps, and whether new feature work currently has a reliable place to add tests -->

## Domain Model Baseline
<!-- Existing CONTEXT.md / CONTEXT-MAP.md layout, relevant ADRs, canonical terms, overloaded or conflicting terminology, and contradictions between domain docs and current code. Mark items that require active Phase 2 refinement. -->

## Project Governance Baseline
<!-- Existing project-level instruction and memory surfaces: AGENTS.md, CLAUDE.md, native project memory, repo-local fallback memory files, Cursor/Windsurf/Cline/Codex rules, or equivalents. Note canonical locations, gaps, and conflicts. -->

## External Integrations
<!-- APIs, databases, services, file systems the project interacts with -->
```

---

## module-inventory.md

```markdown
# Module Inventory

| Module | Coverage | Responsibility | Dependencies | Files | Lines | Complexity | Relevant S.U.P.E.R Findings |
|:-------|:---------|:---------------|:-------------|------:|------:|:-----------|:--------------------------|
|        | deep / shallow |                |              |       |       |            |                 |

> **Relevant S.U.P.E.R Findings**: Record only principles implicated by the module's changed boundary or an observed hotspot. Cite the concrete risk; do not assign a five-principle aggregate score.

## Module Details

### <Module Name>
- **Path**: `src/module_name/`
- **Coverage**: deep / shallow
- **Responsibility**: What this module does
- **Public API**: Key functions/classes exposed to other modules
- **Internal Dependencies**: Which other project modules it imports
- **External Dependencies**: Third-party libraries it uses
- **Complexity Rating**: Low / Medium / High / Critical
- **Transformation Notes**: Specific challenges or considerations for this module
- **Relevant S.U.P.E.R Assessment**: For each applicable principle, cite the changed boundary or observed risk. Do not list unrelated principles.

> **Coverage rule**: Use `deep` only after direct inspection of the module's implementation and relevant call sites. Use `shallow` for inventory-level or indirect evidence; Phase 3 treats its estimates as lower confidence and prefers smaller task cards there.
```

---

## risk-assessment.md

```markdown
# Risk Assessment

## S.U.P.E.R Architecture Health Summary

> Evaluate only S.U.P.E.R principles supported by evidence to identify architectural risks and guide the transformation.

| Principle | Status | Key Findings | Transformation Priority |
|:----------|:-------|:-------------|:------------------------|
| **S** Single Purpose | 🟢/🟡/🔴 | | High / Medium / Low |
| **U** Unidirectional Flow | 🟢/🟡/🔴 | | High / Medium / Low |
| **P** Ports over Implementation | 🟢/🟡/🔴 | | High / Medium / Low |
| **E** Environment-Appropriate | evidence-backed status | | High / Medium / Low |
| **R** Replaceable Parts | 🟢/🟡/🔴 | | High / Medium / Low |

### S.U.P.E.R Violation Hotspots
<!-- List the top evidence-backed modules/files and relevant principles, ranked by severity. These become priority targets in the transformation plan. -->

## Risk Matrix

| Risk | Impact | Likelihood | Severity | Mitigation |
|:-----|:-------|:-----------|:---------|:-----------|
|      |        |            |          |            |

## High-Severity Risks
<!-- Detailed discussion of each high-severity risk -->

## Technical Debt
<!-- Pre-existing issues that may complicate the transformation. Include S.U.P.E.R violations as a category of technical debt. -->

## Testing Risks
<!-- Missing test harnesses, weak regression coverage, slow/flaky tests, or areas where feature work cannot be safely validated yet. -->

## Domain Model Risks
<!-- Missing/stale glossaries, overloaded terms, unclear bounded-context ownership, or ADR/code contradictions that could make scope and acceptance ambiguous. -->

## Project Governance Risks
<!-- Missing or conflicting instruction/memory surfaces, stale instructions, non-native fallback files used without confirmation, or durable decisions that currently exist only in conversation context. -->

## Compatibility Concerns
<!-- API compatibility, data format changes, deployment changes -->
```
