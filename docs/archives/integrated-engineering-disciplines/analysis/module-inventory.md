# Module Inventory

| Module | Responsibility | Dependencies | Files | Complexity | S.U.P.E.R Score | Coverage |
|:-------|:---------------|:-------------|------:|:-----------|:----------------|:---------|
| TAV core | L0/L1 routing and Think-Act-Verify contract | TAV references/templates | 1 primary | Medium | S🟢 U🟢 P🟢 E🟢 R🟢 | deep |
| TAV operational/docs | State mechanics, human docs, version parity, examples | TAV core | 15 support | Medium | S🟢 U🟢 P🟡 E🟢 R🟢 | deep |
| Spec-Driven core | L2 analysis, decomposition, tracking, execution, archive | Shared references/templates and TAV handoff | 1 primary | High | S🟢 U🟢 P🟢 E🟢 R🟢 | deep |
| Spec-Driven references/templates | Single-source behavior, plans, progress, governance | Core skill and agent prompts | 14 primary support | High | S🟢 U🟢 P🟢 E🟢 R🟢 | deep |
| Spec-Driven agents | Analyzer, architect, executor, reviewer contracts | Core skill and shared references | 4 primary | High | S🟢 U🟢 P🟡 E🟢 R🟢 | deep |
| Spec-Driven docs/manifests/validation | User documentation, distribution parity, consistency checks | All workflow surfaces | 10 relevant | Medium | S🟢 U🟢 P🟢 E🟢 R🟢 | deep |

## Module Details

### TAV Core

- **Path**: `D:/WorkSpace/Skills/tav-workflow/SKILL.md`
- **Responsibility**: Provide the mandatory scoped implementation loop.
- **Transformation Notes**: Add hard-bug diagnosis, seam-based TDD, and two-axis review as branches within existing phases rather than new phases or state owners.

### Spec-Driven Core and References

- **Path**: `plugins/spec-driven-develop/skills/spec-driven-develop/`
- **Responsibility**: Own project-level analysis, decision refinement, decomposition, progress, and batch execution.
- **Transformation Notes**: Add domain-modeling, conditional wayfinding, and decomposition strategy as references with concise core pointers.

### Spec-Driven Agent Prompts

- **Path**: `plugins/spec-driven-develop/agents/`
- **Responsibility**: Execute analyzer, architect, coder, and reviewer roles without redefining shared policy.
- **Transformation Notes**: Prompts must consume the new references and preserve fallback parity when TAV is unavailable.

### Validation Surfaces

- **Paths**: `tav-workflow/scripts/verify.ps1`, `spec-driven-develop/scripts/validate.sh`, `spec-driven-develop/scripts/verify.ps1`
- **Responsibility**: Prevent version, reference, manifest, and cross-repository semantic drift.
- **Transformation Notes**: Add targeted semantic fingerprints; do not add runtime dependencies.
