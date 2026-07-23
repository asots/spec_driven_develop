# Behavioral Rules

These rules apply to every agent and every phase in the Spec-Driven Develop workflow. They are non-negotiable.

---

1. **Never skip phases**. Even if you think a phase is unnecessary, at minimum create a lightweight version of its outputs.

2. **Always confirm with the user** before proceeding to the next phase. Each phase boundary is a checkpoint.

3. **Document everything**. If you make a decision, record it in the relevant progress file's "Notes" section.

4. **Progress updates are mandatory**. After completing any task, record its telemetry and implementation state immediately. In GitHub modes, the Issue remains the task record and may stay open while awaiting its delivery batch PR; update MASTER.md's "Current Status", "Issue Mapping", and "Delivery Batches" sections. A merged batch PR closes every completed Issue listed with its own `Closes #N` line. In LOCAL_ONLY mode: update the checkbox in the phase file AND the completion count in MASTER.md.

5. **New conversation = read MASTER.md first**. This is non-negotiable. The master file is your memory across conversations. In GitHub modes, also query GitHub for the latest Issue states — PRs may have been merged since the last session.

6. **Respect the user's time**. Keep summaries concise. Use bullet points and tables, not walls of text.

7. **Archiving is not optional**. When all tasks are done, always enter Phase 6 (Archive). Archive all artifacts to `docs/archives/` for traceability — don't leave them scattered in working directories or delete them.

8. **Dual-write progress updates**. When completing a task, update progress in two places for redundancy. The specific targets depend on the tracking mode:
   - **GitHub modes**: GitHub Issue (task telemetry/status, then closure through its delivery batch PR) + MASTER.md local index. The native platform task tool is an optional third layer.
   - **LOCAL_ONLY mode**: Platform's native task tool (mark as completed) + Markdown progress files (check the box, update counts).
   In all modes, the principle is the same: no single point of failure for progress state.

9. **Use AskUserQuestionTool for all user interactions**. Whenever you need to ask the user a question, request clarification, or get confirmation (including phase boundary checkpoints), you MUST use the platform's built-in `AskUserQuestionTool`. Do not rely on plain text output to ask questions — the tool ensures the user sees and responds to your question directly.

10. **Post-task telemetry is mandatory**. After completing every task, record actual effort, S.U.P.E.R score, and unplanned dependency count BEFORE marking the task as done. This is as non-negotiable as progress updates (rule 4). See `references/adaptive-control.md` § 1 for what to collect and § 4 for where to store it.

11. **Drift threshold triggers are automatic**. When `drift_score` exceeds a threshold, the agent MUST halt and execute the corresponding response action (annotate / replan / rescope) without waiting for user instruction. The thresholds are computed per-phase as percentages of total task count (20% / 40% / 60%). See `references/adaptive-control.md` § 3 for the response protocol.

12. **Adaptive state is persistent**. Always read and write `drift_score` via the defined storage: Milestone description YAML block in GitHub modes, or the "Adaptive Control State" section in MASTER.md for LOCAL_ONLY. Never store adaptive state only in conversation memory — it must survive across sessions.

13. **Project governance surface resolution is mandatory**. Every spec-driven run must resolve shared instruction surfaces, platform-specific instruction surfaces, and the durable memory surface before execution begins. Prefer existing/native surfaces. Typical instruction surfaces include `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.windsurf/`, `.clinerules*`, `.codex/`, or project equivalents.

14. **Do not create competing truth sources**. If a project already has equivalent instruction or memory surfaces, update the canonical surfaces in place and record the resolution in MASTER.md. Use native project memory when available. Do not silently create a repo-local memory file; only use one when the project already declares it or the user explicitly selects it.

15. **Feature work requires tests by default**. Any task that adds or changes user-visible features, business behavior, API contracts, schemas, migrations, parsing, routing, permissions, caching, or persistence must add or update relevant automated tests. If tests are not applicable or the project lacks a test surface, the task must state the reason and run the closest static/syntax validation available.

16. **Stable learnings go to the resolved memory surface**. When execution reveals a reusable command, invariant, project convention, recurring gotcha, or future-agent rule, record it in the resolved native memory surface or the explicitly selected fallback. If it changes how agents should work in the repository, also update the resolved instruction surfaces.

17. **Issues and PRs have different cardinality**. Issues are atomic planning, acceptance, and telemetry units; delivery batches are implementation, integration validation, and PR units. Before editing a phase, review all of its open Issues and form the smallest coherent set of phase-local batches. Default to one reviewable batch PR per phase, not one PR per Issue. Split only for a documented review, release/rollback, ownership, risk-isolation, dependency, or repository-policy boundary — and always when the batch's expected integrated diff exceeds roughly 800 changed lines or 15 files, because an unreviewable PR is not a valid review unit. A single-Issue batch requires an explicit rationale unless it is the only Issue in the phase.

18. **Spec changes flow spec-first**. The user-confirmed spec and acceptance documents are, together with the project-level progress carrier, the single source of truth. When requirements change, update the spec first, then re-derive or adjust task cards — never patch tasks ad hoc while the spec goes stale. Every spec must state goals, non-goals, acceptance criteria, dependencies, and rollback boundaries.

19. **Task cards must be executable and reversible**. Every task card must be completable in a single session, have explicit dependencies, carry runnable acceptance commands, and be independently rollbackable. If a card cannot meet these conditions, fix the decomposition — do not widen the task's scope instead. Acceptance criteria are fixed before execution starts and must not be relaxed mid-task; the Verifier judges independently from the actual diff, affected call sites, and command output — never from the Actor's self-report.

20. **Escalate to the user with evidence**. The following always require an explicit user decision: changes to the spec or acceptance criteria, architectural or irreversible operations, and how to proceed after the same blocker fails twice with the same error fingerprint. Attach concrete evidence when escalating; never silently widen your own authority or scope.

21. **Commits require explicit authorization**. Create commits only after the user explicitly authorizes them, and only for task cards that passed acceptance — one atomic commit per card, referencing the task ID for traceability. After each milestone, distill only reproducible process problems into rule revisions, not one-off incidents.
