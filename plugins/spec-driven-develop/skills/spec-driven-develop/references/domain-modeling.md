# Domain Modeling and Decision Refinement

This reference owns the active domain-modeling and one-decision-at-a-time refinement discipline used during project analysis and Phase 2. Reading an existing glossary or decision record is ordinary evidence gathering; changing the shared language or recording a durable architectural decision activates this discipline.

## Domain Surfaces

Resolve the repository's existing layout before creating anything:

- Single context: root `CONTEXT.md`.
- Multiple bounded contexts: root `CONTEXT-MAP.md` pointing to context-specific `CONTEXT.md` files.
- Decision records: the repository's ADR or decision directory (commonly `docs/adr/`) and decision notes under `.agents/notes/`. Read both as evidence; write new records only through behavioral rule 16's decision-note channel.
- Existing project conventions win. Create a glossary lazily, only when a confirmed term must be recorded.

`CONTEXT.md` is a glossary, not a specification, scratchpad, memory log, or implementation plan. Keep implementation choices in the confirmed spec/task documents or a decision record.

## Analysis Discipline

1. Read the relevant glossary and decision records before using project terminology in analysis or planning.
2. Challenge contradictions immediately: compare the user's statement, existing glossary, current code, and decision records; surface disagreements instead of silently choosing one.
3. Sharpen vague or overloaded terms by proposing one canonical term and explaining the boundary it represents.
4. Stress-test relationships with concrete scenarios and edge cases, especially where two concepts appear similar or lifecycle rules are unclear.
5. Look up facts in the repository, tools, and authoritative documentation. Ask the user only for decisions that cannot be derived from evidence.

## Decision-Grilling Loop

- Resolve one decision at a time, following dependency order. Do not present a batch of unrelated questions.
- Lead with the recommended answer and the evidence/trade-off behind it so the user can accept or redirect quickly.
- Continue until the scope, target, constraints, priorities, testing policy, and domain boundaries required by Phase 2 are jointly understood.
- Do not begin implementation while a decision that changes the confirmed task definition remains unresolved.

## Write-Back

- When a canonical term is confirmed, update the relevant `CONTEXT.md` in the same decision step. Preserve surrounding user content and existing format.
- Record a decision only when it is all three: costly to reverse, surprising without context, and the result of a genuine trade-off. Route it through behavioral rule 16, which owns the decision-note channel and its fallback.
- Record unresolved contradictions or deferred terminology in the Phase 2 task definition's notes/out-of-scope section; do not pretend they are settled.
- Phase 3 tasks that change canonical terms or qualifying architecture decisions must include the matching glossary update or decision note in their acceptance criteria.

## Skill Mapping

When the active platform provides matching skills, execute this discipline through them; this reference remains the authoritative contract wherever they disagree:

- `grilling` — runs the Decision-Grilling Loop: one question at a time, each led by the recommended answer, facts looked up from evidence and only decisions put to the user.
- `domain-modeling` — performs the glossary challenge, scenario stress-testing, and inline `CONTEXT.md` write-back. Its bundled `CONTEXT-FORMAT.md` is the default glossary format when the repository has not established its own; existing project conventions win. Qualifying decisions go through behavioral rule 16 rather than this skill's ADR write-back.

When neither skill is available, apply the sections above directly; decision records still follow behavioral rule 16.
