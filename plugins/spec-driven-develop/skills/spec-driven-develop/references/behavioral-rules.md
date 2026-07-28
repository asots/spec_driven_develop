# Behavioral Rules

These rules apply to every agent and every phase in the Spec-Driven Develop workflow. They are non-negotiable.

---

1. **Never skip phases**. Even if you think a phase is unnecessary, at minimum create a lightweight version of its outputs.

2. **Confirm only meaningful boundaries**. Confirm the task definition in Phase 2, obtain execution confirmation before Phase 5, and stop for a changed scope, acceptance criterion, architecture, irreversible action, or new authority. Routine phase transitions do not require a user interruption.

3. **Record durable decisions, not narration**. Write confirmed scope, rationale, blockers, and plan-invalidating evidence to the canonical progress surface; do not duplicate routine reasoning across Notes, telemetry, and MASTER.md. Persist only compact redacted evidence: never copy secrets, credentials, private user data, or full sensitive logs into local or remote workflow records.

4. **Progress updates are mandatory**. After task completion or batch integration, update the authoritative task record and its lightweight progress mirror according to `references/parallel-protocol.md` "Progress Synchronization". A merged batch PR closes every completed Issue with its own `Closes #N` line.

5. **New conversation = read MASTER.md first**. This is non-negotiable. The master file is your memory across conversations. In GitHub modes, also query GitHub for the latest Issue states — PRs may have been merged since the last session.

6. **Respect the user's time**. Keep summaries concise. Use bullet points and tables, not walls of text.

7. **Archiving is not optional**. When all tasks are done, always enter Phase 6 (Archive). Archive all artifacts to `docs/archives/` for traceability — don't leave them scattered in working directories or delete them.

8. **Progress has one authority and at most one lightweight mirror**. In GitHub modes, the Issue is the task record and MASTER.md mirrors only current phase/batch state. In LOCAL_ONLY mode, the phase file is the task record and MASTER.md mirrors counts/current state. The native task tool is optional and never a second durable truth source.

9. **Use the platform's structured question tool when user input is needed**. Use it for a clarification, a required confirmation, or a genuine decision; do not manufacture routine phase-boundary questions. If the platform lacks such a tool, ask in plain text and wait for an explicit reply.

10. **Execution events are mandatory**. After every task, record observable rework, plan-return, dependency, and focused S.U.P.E.R signals before marking it done. The fields and storage are defined in `references/adaptive-control.md`; remote comments and local state carry only sanitized summaries plus evidence pointers.

11. **Plan-invalidating signals require action**. Apply the adaptive protocol's watch, replan, or rescope response before beginning the next unstarted task. A rescope that changes user-approved scope or acceptance still requires the user's decision.

12. **Adaptive state is persistent**. Read and write the active response state through the authoritative progress surface; never leave it only in conversation memory.

13. **Project governance surface resolution is mandatory**. Every spec-driven run must resolve shared instruction surfaces, platform-specific instruction surfaces, and the durable memory surface before execution begins. Prefer existing/native surfaces. Typical instruction surfaces include `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.windsurf/`, `.clinerules*`, `.codex/`, or project equivalents.

14. **Do not create competing truth sources**. Resolve durable memory in this order: an existing declared project surface (including `MASTER.md` Governance Status) → native project memory → a repo-local fallback only when the project already declares it or the user explicitly selects it. Record the resolution in MASTER.md. This order also governs standalone TAV cycles that later enter a spec-driven project.

15. **Feature work requires tests by default**. Any task that adds or changes user-visible features, business behavior, API contracts, schemas, migrations, parsing, routing, permissions, caching, or persistence must add or update relevant automated tests. If tests are not applicable or the project lacks a test surface, the task must state the reason and run the closest static/syntax validation available.

16. **Stable learnings go to the resolved memory surface**. When execution reveals a reusable command, invariant, project convention, recurring gotcha, or future-agent rule, record it in the resolved native memory surface or the explicitly selected fallback. If it changes how agents should work in the repository, also update the resolved instruction surfaces.

17. **Issues and PRs have different cardinality**. Issues are task, acceptance, and execution-event units; delivery batches are implementation, integration validation, and PR units. Batch design and reviewability signals live in `references/github-integration.md` "Delivery Batch Execution Workflow"; record every split or single-Issue rationale there and in the plan.

18. **Reviewer boundaries are enforced, not advisory**. The orchestrator remains the acceptance-verification authority and single writer for shared state; reviewers follow the commit, branch, external-write, and handoff rules owned by `references/parallel-protocol.md` "Writer model".

19. **Sub-agent dispatch is an economic decision, not a default**. Orchestrator-direct execution is the default; admission, authority, and tiered-review criteria live exclusively in `references/parallel-protocol.md`.

20. **Spec changes flow spec-first**. The user-confirmed spec and acceptance documents are, together with the project-level progress carrier, the single source of truth. When requirements change, update the spec first, then re-derive or adjust task cards — never patch tasks ad hoc while the spec goes stale. Every spec must state goals, non-goals, acceptance criteria, dependencies, and rollback boundaries.

21. **Task cards must be executable and reversible**. Every task card must fit one recoverable TAV cycle, have explicit dependencies, carry runnable acceptance commands, and be independently rollbackable. `XL` is a delivery-batch scope, never an executable task-card size; split it before implementation. A task card may use durable checkpoints across sessions, but it must remain one coherent acceptance and rollback unit. If a card cannot meet these conditions, fix the decomposition — do not widen the task's scope instead. Acceptance criteria are fixed before execution starts and must not be relaxed mid-task; the Verifier judges independently from the actual diff, affected call sites, and command output — never from the Actor's self-report.

22. **Escalate with evidence and keep verification separate from authority**. A second consecutive failure of the same blocker fingerprint always triggers verification escalation: an independent review when available plus a Thinker re-plan before more implementation. It requires an explicit user decision only when the safe next step changes the spec or acceptance criteria, architecture, rollback boundary, irreversible operation, or external authority. Attach concrete evidence when escalating; never silently widen your own authority or scope.

23. **Version-control and external-write authority is explicit**. Create commits only after the user explicitly authorizes them, and only for task cards that passed acceptance — one atomic commit per card, referencing the task ID for traceability. Commit authorization does not authorize branch creation, push, PR creation, or Issue/Milestone/Project edits or comments; each operation class must be explicitly named, although one user statement may authorize several named classes together. After each milestone, distill only reproducible process problems into rule revisions, not one-off incidents.

24. **Resolve decision fog before decomposition**. When Phase 1 shows that blocking research, prototypes, or ordered domain/architecture decisions prevent a confirmable task definition, run the conditional wayfinding gate in `references/wayfinding.md`. Wayfinding produces decisions, not implementation deliverables, and its preparation state never competes with MASTER.md, implementation Issues, delivery batches, or TAV state. External tracker writes still require explicit authorization.

25. **Default behavior changes to vertical tracer slices; wide refactors use expand-contract**. Phase 3 task cards that change runtime behavior should deliver one complete, independently verifiable behavior path through the relevant layers. Foundation/prefactor tasks require a real seam, contract, or test-surface rationale. A wide mechanical change that cannot land green as a vertical slice must use expand → dependency-aware migrate batches → contract, with an explicit integration gate when intermediate batches cannot remain green. Non-behavior operational tasks such as Docs, Governance, Validation, Release, or Archive are allowed when they state why they stand alone and provide a concrete acceptance check. See `references/decomposition-strategy.md`.
