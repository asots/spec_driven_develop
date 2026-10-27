# Behavioral Rules for Spec-Driven Development

This document defines the non-negotiable behavioral rules that govern all phases of the Spec-Driven Development workflow. These rules are read and followed in every phase.

## Rule 1-15: Reserved for Future Definition

These rules cover workflow execution discipline, state management, authorization boundaries, and other core behavioral contracts. They will be defined as needed.

## Rule 16: Decision Recording

**Purpose**: Capture architectural and design decisions that are costly to reverse, surprising without context, or the result of genuine trade-offs.

### Trigger Criteria (ALL three must hold)

A decision qualifies for recording only when it satisfies **all three** criteria:

1. **Costly to reverse** — architectural choice, breaking contract change, schema migration, technology selection, or cross-cutting concern implementation
2. **Surprising without context** — non-obvious constraint, rejected-for-reason alternative, or platform/dependency gotcha that cost rework
3. **Genuine trade-off** — multiple valid options existed at decision time, choice was non-trivial, and at least one meaningful alternative was seriously considered

### Non-Qualifying Examples

Do NOT trigger rule 16 for:
- Obvious bug fixes (even if cross-file)
- Style/formatting changes
- Dependency patches without behavior change
- Implementation detail choices with one clear best practice
- Mechanical CRUD operations
- Routine refactoring within a single module

### Execution Path

**During TAV Phase 4 (Knowledge Consolidation)**:
```
TAV captures decision candidate
  ↓
Evaluates against rule 16 criteria
  ↓ all three hold
Returns decision payload in write-back:
  - Problem context
  - Decision made (現在時)
  - Alternatives considered (with reasons rejected)
  - Consequences (benefits + costs)
  ↓
SDD orchestrator receives payload
  ↓
Routes to write-notes-like-deepseek skill
```

**During SDD Phase 5b (Batch Integration)**:
```
Multiple TAV cycles complete within batch
  ↓
Orchestrator collects decision candidates
  ↓
Batch-level evaluation:
  - Task-level decisions → individual notes
  - Batch-level decisions → batch coordination note
  ↓
Delegate to write-notes-like-deepseek
  ↓
Update MASTER.md § "Governance Status"
```

### Decision Type → WNLD Class Mapping

| Decision Type | WNLD Class | Example |
|---------------|------------|---------|
| User-visible capability | `feature` | New API endpoint, UI behavior change |
| Internal structure/layering | `architecture` | Module boundary, dependency direction, communication protocol |
| Bug + non-obvious root cause | `bug-fix` | Race condition fix, edge case handling |
| Code removal/API narrowing | `simplification` | Deprecated feature removal, interface reduction |
| CI/tooling/workflow | `process` | Build system change, test infrastructure |
| Test strategy/coverage | `testing` | Testing approach, coverage policy, fixture design |

### Payload Format

TAV decision candidates returned to orchestrator must include:

```json
{
  "decision_type": "<type>",
  "problem": "<why this decision was needed>",
  "decision": "<what was chosen, in present tense>",
  "alternatives": [
    {
      "option": "<alternative option>",
      "pros": "<strongest reasons for this option>",
      "rejected_because": "<why it was not chosen>"
    }
  ],
  "consequences": {
    "benefits": ["<benefit 1>", "<benefit 2>"],
    "costs": ["<cost 1>", "<cost 2>"]
  },
  "verification": "<how correctness was verified>",
  "context": {
    "task_id": "<task card identifier>",
    "batch_id": "<delivery batch identifier>",
    "affected_modules": ["<module 1>", "<module 2>"]
  }
}
```

### Orchestrator Responsibilities

When receiving decision candidates from TAV:

1. **Validate completeness**: ensure all required fields are present
2. **Classify decision type**: map to WNLD class using table above
3. **Detect batch-level decisions**: identify decisions spanning multiple tasks
4. **Route to WNLD**: delegate note creation with full payload
5. **Update governance surface**: record note creation in MASTER.md § "Governance Status"
6. **Verify note existence**: confirm `.agents/notes/implemented/<class>/` contains the note
7. **Link from task**: add note reference to completed task in Issue body or phase file

### Batch-Level vs Task-Level Decisions

**Task-level decisions**:
- Affect implementation of one task card
- Written during that task's TAV Phase 4
- Note references that specific task ID

**Batch-level decisions**:
- Shared contract between tasks in the batch
- Delivery shape choice (vertical slice, expand-contract)
- Integration strategy or merge conflict resolution pattern
- Written during batch integration in Phase 5b
- Note references the batch ID and affected tasks

### Skill Mapping

When the platform provides these skills, use them instead of implementing decision capture directly:

- **grilling**: for resolving ambiguous decisions before implementation
- **domain-modeling**: for glossary updates and terminology conflicts
- **write-notes-like-deepseek**: for all decision note creation and updates

The reference documents (`references/domain-modeling.md`, etc.) remain the authoritative contract; skills are the preferred execution mechanism.

### State Recording

Decision capture events are recorded in the authoritative task surface:

- **GitHub modes**: Issue comment includes `[DECISION-RECORDED] <note-path>`
- **LOCAL_ONLY mode**: phase file task entry includes `Decision: <note-path>`

MASTER.md mirrors the fact that a note was created but does not duplicate its content.

### Post-Capture Verification

After WNLD writes the note:

1. Orchestrator reruns `git diff` to inspect the new file
2. Runs WNLD verification scripts (`npm run verify-notes` or equivalent)
3. Confirms note passes format and classification checks
4. Only then marks the task as complete in authorized surfaces

Decision note verification failures are reported but not fatal; the candidate is returned to the user for manual resolution rather than blocking task completion.

## Rules 17-25: Reserved for Future Definition

Additional behavioral rules covering testing, security, integration, and completion criteria will be defined as needed.
