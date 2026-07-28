# Wayfinding Protocol

Wayfinding is a conditional preparation loop for a destination that is too large or uncertain to turn into a confirmed task definition in one Phase 2 pass. It resolves decisions, not implementation deliverables.

## Trigger and Exit

Enter the gate after Phase 1 only when at least one blocking decision cannot yet be stated and resolved from the analysis — for example, the route depends on research, a prototype, or several ordered domain/architecture choices. A large but already well-scoped transformation does not need wayfinding.

Exit when the destination and route are clear enough for Phase 2 to confirm scope, target, constraints, priorities, testing policy, and governance. The gate does not produce implementation tasks; Phase 3 owns those.

## State Ownership

- Wayfinding state is preparation state. It never replaces `docs/progress/MASTER.md`, implementation Issues, Milestones, delivery batches, or TAV state.
- In LOCAL_ONLY mode, use `docs/analysis/wayfinding/MASTER.md` as the map and one file per decision under `docs/analysis/wayfinding/decisions/`.
- In GitHub modes, use external map/decision Issues only after explicit authorization for those writes. If authorized, the tracker is authoritative and the local analysis documents contain links plus a low-resolution summary; do not dual-maintain full decision bodies.
- Concurrent sessions claim one decision before work using the tracker's assignee mechanism or a local `Claimed by` field. Never let two sessions resolve the same decision.

## The Map

The map is a low-resolution index with five sections:

```markdown
# Wayfinding Map

## Destination
<the spec, decision, or target state this effort is finding a route toward>

## Notes
<standing constraints, domain surfaces, required skills/references>

## Decisions So Far
- [Decision title](decision-link) — one-line outcome

## Not Yet Specified
- <in-scope fog that cannot yet be phrased as a precise decision>

## Out of Scope
- <work deliberately beyond the destination, with reason>
```

The map indexes outcomes; each decision's evidence and resolution live in exactly one decision record.

## Decision Records

Each record resolves one question that fits a fresh agent session:

```markdown
# <Decision title>

## Question
<the precise decision or investigation>

## Type
research | prototype | grilling | investigation

## Blocked By
<decision identifiers or none>

## Status
open | claimed | resolved | out-of-scope

## Resolution
<filled only when resolved, with evidence and links to produced assets>
```

- **Research** obtains facts from primary sources or local evidence.
- **Prototype** creates a cheap, explicitly disposable artifact to answer a behavior or interface question.
- **Grilling** uses `domain-modeling.md` to resolve a human decision one question at a time.
- **Investigation** runs a bounded diagnostic or disposable probe needed to expose facts for a later decision. It may not leave persistent product changes behind; any retained implementation belongs in a Phase 3 task card.

## Frontier and Fog

- The **frontier** is the open, unclaimed set whose blockers are all resolved.
- A precise question is a decision record even when blocked. An area that cannot yet be phrased precisely remains under **Not Yet Specified**.
- Resolving one record may graduate fog into new decisions, invalidate existing records, or reveal work as out of scope. Update the map immediately so each fact has one home.
- Each agent keeps only one active non-research decision at a time. A session may resolve several decisions sequentially after each record is written back and released; independent research records may run in parallel when their evidence sources and output files do not overlap.

## Work Loop

1. Name and confirm the destination boundary.
2. Chart the current frontier and fog; stop if the route is already clear enough for Phase 2.
3. Create precise decision records, then add blocking edges in a second pass.
4. Select and claim one frontier decision, gather only the evidence needed, and resolve it.
5. Append the one-line outcome to the map, update fog/out-of-scope, and create newly visible decisions.
6. When no blocking decisions or relevant fog remain, summarize the resolved route into the Phase 2 confirmed task definition and continue the normal workflow.
