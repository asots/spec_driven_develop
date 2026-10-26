---
name: spec-driven-develop
description: >-
  Plans and executes large transformations (rewrites, migrations, overhauls, architecture-level
  refactors) through project analysis, task decomposition, recoverable progress tracking, and
  batched PRs. Use only when at least two L2 signals hold: 3+ modules or a public contract break;
  multi-session or ~10+ files; architectural decisions; acceptance cannot fit one TAV cycle.
  Chinese cues: 整体重构, 全项目重构, 跨模块迁移, 架构级改造, 大规模, 规范驱动. A bare
  rewrite/refactor/migration keyword is not enough; single-module work belongs to tav-workflow.
metadata:
  version: 1.26.0
---

# Spec-Driven Develop

You are executing the **Spec-Driven Development** workflow — a seven-phase pipeline (Phases 0-6) for large-scale complex tasks. Preparation and execution may span sessions; persist and resume from the approved task definition and `docs/progress/MASTER.md` rather than relying on conversation memory.

**Behavioral rules**: `references/behavioral-rules.md` — read and follow them in every phase; they are non-negotiable.

## Configuration

| Path | Default Value | Purpose |
|:-----|:--------------|:--------|
| Analysis output | `docs/analysis/` | Phase 1 analysis documents |
| Plan output | `docs/plan/` | Phase 3 planning documents |
| Progress output | `docs/progress/` | Phase 4 tracking documents (incl. MASTER.md) |
| Instruction surfaces | Resolved per project | Project-level constraints for agents (see Phase 4) |
| Memory surface | Declared surface → native → explicit repo fallback | Durable facts use the project-declared surface first; a repo fallback is never silently created |
| Archive output | `docs/archives/<project-name>/<run-id>/` | Phase 6 archived artifacts |
| Task tracking mode | Capability-detected, user-confirmed | `GITHUB_FULL`, `GITHUB_STANDARD`, or `LOCAL_ONLY` |
| Delivery batching | Phase-first | Issues track tasks; PRs integrate coherent task batches |
| Adaptive control | Enabled | Observable execution events drive normal, watch, replan, or rescope responses |

**Canonical references** (each topic has exactly one home — cite it, never re-explain it):

| Reference | Owns |
|:----------|:-----|
| `references/behavioral-rules.md` | All behavioral rules (1-25) |
| `references/github-integration.md` | Tracking modes, pre-flight check, all `gh` commands and Issue/PR body templates |
| `references/adaptive-control.md` | Execution events, response levels, canonical storage, controller activation |
| `references/parallel-protocol.md` | Dispatch/review admission (tiers), lane/worktree protocol, review loop, merge risk, post-integration checks |
| `references/super-philosophy.md` | S.U.P.E.R principles + the 10-check review checklist |
| `references/domain-modeling.md` | Domain surfaces, evidence-driven terminology, one-decision-at-a-time refinement, glossary write-back, decision-record routing |
| `references/wayfinding.md` | Conditional decision map for efforts whose route is still too foggy for Phase 2 confirmation |
| `references/decomposition-strategy.md` | Vertical tracer slices, prefactoring boundaries, and expand-contract for wide refactors |
| `references/archive-protocol.md` | Phase 6 archive path rules, authorization and verification order, tombstone creation, execution retrospective |
| `references/templates/` | Schemas for every generated document (including the Phase 2 task definition, analysis, plan, progress, governance, archive) |

**Task tracking modes** describe task-record surfaces only. Detection and upgrade instructions live in `references/github-integration.md` § "Pre-flight Check"; branch/worktree, commit, push, PR, and tracker-write permissions remain independent authority gates:

- **GITHUB_FULL**: Issues + Milestones + Labels + Project board
- **GITHUB_STANDARD**: Issues + Milestones + Labels, without a Project board
- **LOCAL_ONLY**: local plan and phase files, without a remote tracker

## When Not to Use

Do not use this workflow for small scoped fixes, single-file edits, or changes that can be implemented cleanly without a project-wide planning pass. Use `tav-workflow` for those cases instead.

### Escalation Signals

Keep this list in sync with `tav-workflow` § "L2 Escalation Signals" — both skills must apply the same test. Route to `spec-driven-develop` only when **at least two** of these hold; otherwise stay with `tav-workflow`:

- The change spans 3+ modules/subsystems, or breaks a public API/schema contract.
- The work will realistically span multiple sessions or exceed ~10 files.
- Architectural decisions are required (layering, dependency direction, technology selection).
- Acceptance criteria cannot be defined within a single Thinker-Actor-Verifier cycle.

A refactor confined to one module — however messy — stays at L1 (TAV territory).

## Before You Begin: Cross-Conversation Continuity Check

**CRITICAL**: Before starting any phase, inventory and read any existing project-level instruction and memory surfaces (`AGENTS.md`, `CLAUDE.md`, existing platform rule files, the active agent's native project memory, any repo-local fallback memory file already declared by the project or by an existing `docs/progress/MASTER.md`).

Then check if `docs/progress/MASTER.md` already exists:

- If it **exists**: Read it immediately, then compare its task name, workflow run ID, and latest session summary with the current request. Resume only when they describe the same approved workflow and the state is not stale (more than 7 days without a matching user request). If it is stale or describes a different task, ask the user before resuming, replacing, or archiving it. Do NOT restart from Phase 0 without that decision.
  - **In GitHub modes**: Also query GitHub for the latest status scoped to the recorded workflow run ID — see `references/github-integration.md` § "Reading Progress from GitHub". Update MASTER.md if remote state is ahead of the local index.
- If it **does not exist**: This is a fresh start. Proceed to Phase 0.

An archived snapshot does not replace the active root-level recovery entry while remote synchronization or cleanup remains pending. A tombstone is identified by the exact `**Workflow State**: archived` marker and follows `references/templates/progress.md` "Archived MASTER.md Tombstone". If `Pending Operations` is `none`, the archived run is complete and a different current request starts fresh at Phase 0. If pending operations are listed, follow the archive pointer and resume only those recorded operations; do not reconstruct active task execution from the tombstone.

After loading your current state, populate the platform's native task tracking tool when available (for example, `TaskCreate` / `TaskUpdate`) with the active phase's pending tasks: content = task description, status = in-progress for the active task, priority mapped P0=high, P1=medium, P2=low. If no native task tool is available, skip this step — MASTER.md alone is sufficient.

---

## Phase 0: Quick Intent Capture

**Goal**: Capture the user's high-level transformation direction in 1-2 sentences — just enough to give Phase 1 analysis a focus.

**Actions**:

1. Extract from the user's message: the transformation type, the rough target state, and any explicitly stated constraints.
2. Summarize the direction back in 1-2 sentences. Do NOT ask deep clarifying questions here — Phase 1 analysis will reveal what to ask. Confirm: "I understand you want to [direction]. Let me first analyze the current project so I can ask you the right questions."
3. If intent is completely unclear, ask ONE high-level question to determine the transformation type.

**Output**: A preliminary direction statement guiding Phase 1. NOT the final task definition — that comes in Phase 2.

---

## Phase 1: Deep Project Analysis

**Goal**: Build a comprehensive understanding of the current codebase, informed by the Phase 0 direction.

**Actions**:

1. Launch `project-analyzer` sub-agents **in parallel**, split by focus area:
   - **Architecture & Stack**: structure, directory layout, tech stack, entry points, build/run commands
   - **Module Inventory**: each module's responsibility, public API surface, size, dependencies, and the S.U.P.E.R principles relevant to its risk profile
   - **Risks, Tests, Domain & Governance**: transformation risks, complexity hotspots, coding conventions, test coverage, domain glossaries/decision records and terminology contradictions, instruction/memory surfaces — plus S.U.P.E.R violation hotspots (priority targets for the plan)

   Give each agent the Phase 0 direction AND `references/super-philosophy.md`. If sub-agents are unavailable, perform the same analysis sequentially yourself.

   **Scale the analysis to the repository.** The three-agent split above assumes each agent can deep-read its focus area. For large codebases (roughly 100+ modules or beyond ~200k LOC), partition the repository by subsystem (top-level directory or build unit), launch one Module Inventory agent per partition alongside the Architecture and Risk agents, and merge partition outputs into a subsystem-level rollup in `module-inventory.md`. Whatever the strategy, every analysis document must mark areas that were not deep-read with `coverage: shallow` — Phase 3 treats estimates for shallow-coverage areas as low-confidence and prefers smaller task granularity there.

2. Consolidate outputs, resolve contradictions, and write `docs/analysis/` documents from `references/templates/analysis.md`:
   - `project-overview.md` — Architecture, tech stack, entry points, build system, domain-model baseline
   - `module-inventory.md` — Every module with: responsibility, dependencies, size, complexity rating, relevant S.U.P.E.R considerations, and a coverage marker (`deep` or `shallow`); large repositories add a subsystem-level rollup section
   - `risk-assessment.md` — Technical risks, compatibility risks, complexity hotspots, testing gaps, project governance gaps, and prioritized S.U.P.E.R violation hotspots

3. **GitHub Pre-flight Check**: detect the tracking mode per `references/github-integration.md` § "Pre-flight Check". Report the detected mode; if it differs from user expectation, explain how to upgrade (e.g., `gh auth refresh -s project`).

**Output**: Complete `docs/analysis/` (three documents) + detected tracking mode. Relevant S.U.P.E.R findings are the architectural baseline for subsequent phases.

### Conditional Wayfinding Gate

After Phase 1, evaluate whether the analyzed destination can be turned into a confirmed task definition in one grounded Phase 2 discussion. If blocking decisions still depend on ordered research, prototypes, or domain/architecture choices, run `references/wayfinding.md` before Phase 2.

- Wayfinding resolves decisions, not implementation deliverables. It may use explicitly disposable probes, but it must not retain task-level code changes or bypass Phase 2 confirmation and Phase 3 decomposition.
- Its map is preparation state only. `docs/progress/MASTER.md` remains project-level progress authority once created; implementation Issues and TAV state retain their existing ownership.
- Use LOCAL_ONLY analysis files by default. External tracker map/decision writes require explicit authorization even when a GitHub tracking mode was detected.
- When the route is clear, summarize the resolved decisions into the Phase 2 inputs and continue the normal seven-phase pipeline. If the gate is not triggered, note that the route was already clear in `risk-assessment.md`.

---

## Phase 2: Intent Refinement & Confirmation

**Goal**: With the project analyzed, finalize the task definition through a grounded discussion.

**Actions**:

1. Present key Phase 1 findings: brief architecture summary, notable S.U.P.E.R health issues, and coupling/complexity highlights relevant to the transformation.
2. Read `references/domain-modeling.md`, which owns the evidence, one-active-decision, glossary, and decision-record rules. Resolve blocking terminology or domain-boundary conflicts before freezing scope and return links to any confirmed write-back. When the platform provides the `grilling` and `domain-modeling` skills, run the decision loop and the glossary write-back through them, with qualifying decisions recorded through behavioral rule 16 (see that reference's "Skill Mapping"); the reference remains the authoritative contract.
3. Ask **targeted questions grounded in the analysis** — specific and informed, not generic (e.g., about circular dependencies found, hardcoded environment assumptions, missing interface contracts). At minimum confirm:
   - **Scope** — which modules from the inventory are in scope
   - **Target** — target technology/architecture/state
   - **Constraints** — timeline, backward compatibility, libraries, deployment targets
   - **Priorities** — performance, maintainability, feature parity (use the risk assessment)
   - **S.U.P.E.R priorities** — which violations to fix now vs. defer
   - **Testing policy** — which test layers protect changes; whether to establish a minimal test harness if none exists
   - **Project governance** — canonical instruction surfaces; native memory surface or explicitly named repo fallback

4. Summarize the refined understanding, including resolved domain terms/decisions and any deferred ambiguity, then get explicit confirmation.

**Output**: Write the authoritative confirmed definition to `docs/plan/task-definition.md` using `references/templates/task-definition.md`. Generate one immutable workflow run ID and record it there before Phase 3; it scopes any GitHub resources and recovery ledger for this workflow attempt. This is the single spec source for Phases 3-6; `task-breakdown.md`, phase files, and Issue bodies reference it rather than restating or redefining approved scope. Include any glossary updates and decision notes made through `references/domain-modeling.md`.

---

## Phase 3: Task Decomposition

**Goal**: Break the transformation into manageable, trackable tasks organized in phases, with parallel lanes and coherent delivery batches.

**Actions**:

1. Launch `task-architect` sub-agents with the full Phase 1 analysis AND `docs/plan/task-definition.md`. If multiple strategies are plausible, launch 2 agents exploring different approaches (e.g., bottom-up vs. strangler fig) and pick the better result. If sub-agents are unavailable, decompose yourself.
2. Apply `references/decomposition-strategy.md` before assigning phases, lanes, or delivery batches. It owns behavior-slice defaults, expand-contract, operational-task categories, exception rationales, and genuine-blocker rules; record the selected delivery shape on every task card.
3. The decomposition must produce:
   - **Phases** ordered by dependency; early phases prioritize fixing S.U.P.E.R violation hotspots before new features.
   - **Tasks**, each with: description, priority (P0/P1/P2), effort (S/M/L/XL), dependencies, declared affected files/modules/contracts/prerequisites, S.U.P.E.R design drivers, acceptance criteria, test expectation, and memory/governance impact. Every task's acceptance criteria implicitly include passing the S.U.P.E.R Quick Check for its listed principles.
     - **Testing is default**: tasks changing user-visible features, behavior, API contracts, schemas, migrations, parsing, routing, permissions, caching, or persistence MUST add or update automated tests; documentation/config tasks may mark tests N/A with an explicit reason.
     - **Governance is default**: tasks introducing a stable rule, gotcha, or convention must include updating the resolved memory surface (and instruction surfaces if the rule affects future agents).
   - **Parallel execution lanes** per phase: group mutually independent tasks; assess merge risk (file overlap).
   - **Delivery batches** per `references/behavioral-rules.md` rule 17: assign every task to exactly one batch and record ID, goal, task IDs, execution waves, lanes, integration branch, combined validation, dependency order, shared contracts, and split rationale.
   - **Dependency graph** as a Mermaid diagram (subgraphs for batch boundaries and lanes) and **milestones** at phase boundaries. Every milestone criterion must be a runnable command or concretely observable check; each phase ends with a milestone acceptance task that runs the combined regression and blocks closure on failure.
4. Write `docs/plan/` documents from `references/templates/plan.md`: `task-breakdown.md`, `dependency-graph.md`, `milestones.md`. They must link to the confirmed `task-definition.md`, not duplicate its scope or acceptance terms.
5. **GitHub Resource Synchronization**: capability detection is read-only. Before the first authorized GitHub write, create `docs/plan/github-sync.md` from `references/templates/github-sync.md` with the immutable run ID, repository, planned markers, and `prepared` state. Create Labels → Milestones → Issues → [GITHUB_FULL only] Project board only after explicit GitHub tracker-write authorization, using the exact idempotent lookup and Issue body protocol in `references/github-integration.md`. After each successful remote create or reuse, immediately record the stable ID and URL in the ledger before continuing. If authorization is not granted, preserve the confirmed tracking mode, record `awaiting tracker-write authorization`, and stop before external writes. Switch to `LOCAL_ONLY` only through a user-approved Phase 2 task-definition update. Issue creation never implies commit, push, or PR authorization.
6. **Establish adaptive records**: configure the authoritative task record and lightweight progress mirror per `references/adaptive-control.md`. Do not create numeric drift thresholds or Milestone YAML state.

**Output**: Complete `docs/plan/` (`task-definition.md`, `task-breakdown.md`, `dependency-graph.md`, `milestones.md`). In GitHub modes, report remote state precisely: `prepared` or `awaiting_authorization` when resources are only planned locally, `syncing`/`blocked` for partial work, and `complete` only when every task exists as a labeled, milestoned Issue and all in-scope resource identities are recorded.

---

## Phase 4: Progress Tracking Documentation

**Goal**: Create a progress tracking and governance system that survives across conversations.

**Actions**:

Use `references/templates/progress.md` for progress documents and `references/templates/governance.md` for governance records.

### Project Governance Surface (all modes)

1. **Inventory existing surfaces**: shared instruction files (`AGENTS.md` or equivalent), `CLAUDE.md`, existing platform rule files, the agent's native project memory, and repo-local fallback memory files only if they already exist or the user explicitly selects one.
2. **Update instruction surfaces without overwriting**: shared cross-agent rules → `AGENTS.md`; Claude Code-specific → `CLAUDE.md`; platform rule files only when they already exist or are requested. Preserve user-written sections, local commands, and security constraints. If an existing rule conflicts with the plan, do not silently replace it — record the conflict in MASTER.md and ask the user at the next checkpoint.
3. **Resolve the memory surface**: use an existing declared project surface first (including a prior Governance Status), otherwise native project memory, then a repo-local fallback only on user confirmation or existing project declaration. Never silently create a Markdown memory file. Record the resolution in MASTER.md "Governance Status"; the same order applies when a standalone TAV cycle later enters this project.

Do not create competing truth sources.

### In GITHUB_FULL or GITHUB_STANDARD mode:

1. Create `docs/progress/MASTER.md` as a **lightweight GitHub index**: task name/description, tracking mode, repository, Project URL (GITHUB_FULL), links to analysis/plan documents, milestone table, delivery batch table, "Quick Status Commands", "Current Status", "Next Steps". Do NOT duplicate task details or a task-by-task Issue map — those live in GitHub Issues and `task-breakdown.md`.
2. Record that Issue execution events are authoritative and MASTER.md mirrors only the active phase, delivery batch, blocker, and response level.
3. Per-phase detail files are optional and lightweight (Issue references only).

### In LOCAL_ONLY mode:

1. Create `docs/progress/MASTER.md`: task name/description, `LOCAL_ONLY` mode, links to analysis/plan documents, phase summary table, links to phase files, "Current Status", "Next Steps".
2. Create one `docs/progress/phase-N-<short-name>.md` per phase: checkbox tasks with inline acceptance criteria plus a "Notes" section.
3. Record task execution events in each phase-file task entry; MASTER.md mirrors phase counts, current task, blocker, and response level.

### Common to all modes:

- Phases use `- [ ] Phase N: <name> (0/X tasks)` linking to the phase file (LOCAL_ONLY) or milestone URL (GitHub modes); `- [x] Phase N: <name> (X/X tasks)` when done.
- "Current Status" is updated at the start and end of each work session.
- Keep only the active batch and current response in MASTER.md. The authoritative task events remain in Issues (GitHub modes) or phase files (LOCAL_ONLY), so MASTER.md stays readable in one screen on large projects.

**Output**: Complete `docs/progress/` with MASTER.md (plus phase files in LOCAL_ONLY).

---

## Phase 5: Confirm & Execute

**Goal**: Present preparation artifacts, get confirmation, then execute the plan.

**Actions**:

### 5a. Summary & Confirmation

1. Present: task definition (Phase 2), key findings (Phase 1), phased plan with task counts (Phase 3), delivery batch overview with PR count and split rationales (Phase 3), tracking mode and its implications, progress system description (Phase 4), and the execution model (tiered dispatch: orchestrator-direct by default; `task-executor`/`code-reviewer` sub-agents dispatched per `references/parallel-protocol.md` § "Dispatch Admission (Tiered Execution)").
2. List all generated artifacts (analysis, plan, and progress documents; resolved instruction and memory surfaces; GitHub Project URL, Milestone URLs, Issue numbers, batch mapping in GitHub modes).
3. Ask the user: "All preparation is complete. Ready to begin execution?"

### 5b. Execution

1. **Process each phase sequentially.** In GitHub modes, first confirm explicit tracker-write authorization that includes Issue comments; the authoritative execution-event record cannot be replaced by a local mirror. If it is absent, stop as `awaiting tracker-write authorization` or return to Phase 2 for a user-approved LOCAL_ONLY switch. Then read every open Issue in the phase and revalidate the planned batches against current dependencies, affected files, review scope, and repository rules. If the mapping must change, update `task-breakdown.md`, MASTER.md, and the `Delivery Batch` field in every affected Issue body; comment the regrouping reason so all execution surfaces agree.

2. **Choose the execution tier for each delivery batch** using `references/parallel-protocol.md` "Dispatch Admission (Tiered Execution)". Tier 0 direct execution is the default; Tier 1 delegates a context-heavy complete batch; Tier 2 requires every admission and authority condition before lanes or worktrees exist. These `Tier 0/1/2` dispatch tiers are independent from TAV's `L0/L1/L2` task tiers for scope and risk. The reference owns branch conventions, wave dispatch, and the downgrade path.

3. **Review before integrating** using `references/parallel-protocol.md` "Review Admission (Tiered Review)". L1 machine validation and L2 separate Standards/Spec diff review always apply; L3 independent review is reserved for its stated risk cases. You remain the acceptance-verification authority and sole writer of shared progress, adaptive, governance, and external-tracker state; commit, branch, push, PR, and tracker writes retain their independent authority gates.

4. **After each task completion** — follow `references/adaptive-control.md` "Controller Activation": the orchestrator records one observed execution event in the authorized Issue comment (GitHub modes) or phase file (LOCAL_ONLY), updates the lightweight MASTER.md mirror once, and applies the resulting normal, watch, replan, or rescope response before the next unstarted task. For parallel lanes, lane agents return events and you record them once during batch integration.

Every task card runs as one TAV cycle (Thinker → Actor → Verifier), even when several tasks share a batch or lane. Keep task-level plans, acceptance verdicts, and execution signals distinct; load `tav-workflow` when available, otherwise use the equivalent discipline embedded in `task-executor`. See § "Boundary with TAV".

5. **Integrate and validate each delivery batch** per `references/github-integration.md` § "Delivery Batch Execution Workflow":
   - Consolidate reviewed lane branches onto the batch integration branch; reconcile overlaps.
   - Run per-task checks plus combined validation and post-integration architecture checks.
   - Verify every included Issue's acceptance criteria yourself (L2). Keep incomplete Issues out of closing keywords.
   - When commit, push, and PR authorization are all explicit, create exactly one batch PR with one `Closes #N` per completed Issue. Immediately write the PR number and `in review` state to the batch row and `Current Status` in MASTER.md; keep partial Issues open with explicit partial status in their authoritative Issue records. Without those authorizations, stop after local integration validation and report the ready branch/diff without remote writes.
   - A single-Issue PR is allowed only for a documented exception or a one-Issue phase.

6. **Progress updates**:
   - **GitHub modes**: merged batch PRs auto-close their Issues; update MASTER.md "Current Status" and "Delivery Batches" once per batch transition.
   - **LOCAL_ONLY**: check off tasks in phase files; update MASTER.md counts.
   - **All modes**: durable knowledge → resolved memory surface; agent-behavior changes → resolved instruction surfaces; decision-type knowledge (costly to reverse, genuine trade-off, rejected alternatives worth recording) → decision note through `write-notes-like-deepseek` per behavioral rule 16.

7. **At each phase boundary**: the phase's milestone acceptance task must pass before the phase closes — a failure there is a gate failure (return to the offending batch or task, or trigger adaptive replan if it reveals plan-level drift). Close the Milestone only after it passes.

8. **When all tasks pass local acceptance and integrated validation**: perform any separately authorized remote synchronization. If remote close/merge authority is absent, record `locally validated — awaiting remote sync` in the local mirror; do not claim Issues are closed. Proceed to Phase 6 only under the corresponding trigger.

**Output**: All planned tasks implemented and verified.

---

## Phase 6: Archive

**Trigger**: All tasks have passed local acceptance and integrated validation. GitHub-mode tasks are either closed in the authorized remote workflow or explicitly recorded as `locally validated — awaiting remote sync`; LOCAL_ONLY tasks have all checkboxes `[x]`.

Before archiving, read `references/archive-protocol.md`; it owns the archive path rules, authorization and verification order, tombstone creation, and execution retrospective. Output goes to `docs/archives/<project-name>/<run-id>/`.

---

## Boundary with TAV

Spec-Driven Develop owns analysis, decomposition, delivery-batch orchestration, and progress scaffolding. `tav-workflow` owns the scoped implementation loop: during Phase 5b, one TAV cycle executes exactly one task card, while the enclosing batch coordinates shared branches, integration validation, and PR creation. Spec Phases 0-6 and TAV Phases 0-4 are independent numbering systems. This contract is mirrored in `tav-workflow` § "Operating Inside a Spec-Driven Project" — keep both sides in sync.

**Handoff contract ID**: `spec-tav/v1` (canonical here; mirrored by `tav-workflow`).

### Handoff Contract (per task)

**Input mapping — what each task card gives the TAV cycle:**

| Task card field (Issue / task-breakdown.md / executor input) | TAV consumer |
|:-------------------------------------------------------------|:-------------|
| Task description | Thinker task definition (`user_request`) |
| Acceptance criteria + test expectation | Baseline of the Thinker verification plan |
| S.U.P.E.R design drivers | Additional Verifier check items |
| Relevant files / dependencies | Starting points for Thinker evidence gathering |
| Delivery batch, delivery shape, and rollback boundary | Execution order, scope boundary, and safe recovery constraints |
| Memory/governance impact | Pre-declared candidates for the cycle's Phase 4 knowledge consolidation |

**Write-back mapping — what the finished TAV cycle returns:**

| TAV outcome | Spec-Driven update |
|:------------|:-------------------|
| Verifier pass | TAV returns `ready for batch integration`; after integrated validation, the orchestrator marks project status and only performs authorized closure through the batch PR's `Closes #N` line or LOCAL_ONLY completion updates |
| TAV execution signals (rework iterations, Thinker returns, unplanned files touched) | TAV returns one execution-event payload with Outcome, Rework, Plan returns, Unplanned dependencies, and Focused S.U.P.E.R result; the orchestrator records it once in the authoritative surface (see `references/adaptive-control.md`) |
| Knowledge consolidation captures (at most 1-3 durable rules per cycle) | TAV returns candidates; the orchestrator reconciles and writes authorized updates to the surfaces resolved under "Governance Status" in MASTER.md — durable facts to memory, agent-behavior rules to instructions |
| `[ESCALATION-REPORT]` or blocked state | TAV returns the event; the orchestrator records it in an authorized Issue comment or phase-file note and selects the response level |

**State ownership:**

- `docs/progress/MASTER.md` is the project-level lightweight status authority.
- GitHub Issues (GitHub modes) or phase-file task entries (LOCAL_ONLY) are the authoritative task-event records.
- `.tav/state.json` is scoped to one task: it is created only when that single task needs cross-session recovery, it is archived or deleted with explicit cleanup authorization when the task completes, and it never carries project-level progress.
