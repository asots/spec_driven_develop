# Risk Assessment

## S.U.P.E.R Architecture Health Summary

| Principle | Status | Key Findings | Transformation Priority |
|:----------|:-------|:-------------|:------------------------|
| S — Single Purpose | 🟢 | TAV and Spec-Driven have clear micro/macro ownership | High: preserve boundary |
| U — Unidirectional Flow | 🟢 | Spec task cards flow into TAV; TAV writes outcomes back | High: avoid reverse ownership |
| P — Ports over Implementation | 🟡 | Cross-repo handoff exists, but specialist disciplines are not yet explicit | High |
| E — Environment-Agnostic | 🟡 | Source rules contain Claude/Unix assumptions that must not be copied literally | High |
| R — Replaceable Parts | 🟢 | References and agent prompts are independently replaceable | Medium |

**Overall Health**: 3/5 fully healthy — targeted workflow extension required, not an overhaul.

## Risk Matrix

| Risk | Impact | Likelihood | Severity | Mitigation |
|:-----|:-------|:-----------|:---------|:-----------|
| Duplicate policy across skills/prompts | Rules drift and contradictory agents | High | High | Single-source detailed rules; prompts point to references |
| Source authorization leakage | Automatic commits or tracker writes | Medium | Critical | Explicitly exclude those source behaviors; preserve current guardrails |
| Wayfinding becomes a second progress source | Resume ambiguity | Medium | High | Keep it preparation-only under analysis; MASTER remains project progress authority |
| TDD creates unnecessary user checkpoints | Execution stalls | Medium | Medium | Confirm seams only when the choice changes scope/architecture |
| Two-axis review replaces machine gates | False confidence | Medium | High | Run Standards/Spec review after, never instead of, machine validation |
| Version or docs parity drifts | Broken installation/cache behavior | Medium | High | Minor-version bumps plus existing parity checks |
| Broad prompt duplication | Context bloat | Medium | Medium | Keep prompt changes concise and refer to canonical references |

## Testing Risks

- Markdown semantics are not executable behavior, so regressions require phrase/section fingerprints in addition to existing structural checks.
- `scripts/validate.sh` requires a POSIX shell and `python3`; on this Windows host it must run through Git Bash with a temporary Python command mapping.

## Project Governance Risks

- `AGENTS.md` requires core, references/templates, prompts, and bilingual READMEs to remain synchronized.
- No native project memory writer is exposed; no repository fallback memory will be invented.

## Compatibility Concerns

- Do not hard-code Claude `Agent` names or slash-command invocation.
- Do not copy the source `implement` skill's automatic commit behavior.
- Do not require GitHub tracker writes during wayfinding or decomposition without explicit authorization.
