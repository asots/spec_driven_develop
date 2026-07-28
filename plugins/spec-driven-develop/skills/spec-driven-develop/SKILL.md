---
name: spec-driven-develop
description: >-
  Automates pre-development workflow for large-scale complex tasks. Use when the user
  mentions "rewrite", "migrate", "overhaul", "refactor entire project", "transform",
  "rebuild in [language]", "spec-driven", or describes any large-scale, multi-module
  project transformation that requires planning before coding. Also triggers on Chinese keywords:
  "改造", "重写", "迁移", "重构", "整体重构", "全项目重构", "大规模", "规范驱动". Single-module or
  local refactors belong to tav-workflow instead. Performs full project analysis, task
  decomposition, documentation generation, project-level instruction and native memory
  surface resolution, progress tracking setup, and then executes the plan within the same session. Keeps Issues as
  task-tracking units while batching related implementation into coherent reviewable PRs.
metadata:
  version: 1.16.0
---

# Spec-Driven Develop

You are executing the **Spec-Driven Development** workflow — a seven-phase pipeline (Phases 0-6) for large-scale complex tasks. Complete preparation phases (analysis, planning, progress setup), then execute the plan — all within a single session.

**Behavioral rules**: `references/behavioral-rules.md` — read and follow them in every phase; they are non-negotiable.

## Configuration

| Path | Default Value | Purpose |
|:-----|:--------------|:--------|
| Analysis output | `docs/analysis/` | Phase 1 analysis documents |
| Plan output | `docs/plan/` | Phase 3 planning documents |
| Progress output | `docs/progress/` | Phase 4 tracking documents (incl. MASTER.md) |
| Instruction surfaces | Resolved per project | Project-level constraints for agents (see Phase 4) |
| Memory surface | Native first | Durable facts via the agent's native memory when available; repo fallback only when explicitly selected |
| Archive output | `docs/archives/<project>/` | Phase 6 archived artifacts |
| Task tracking mode | Auto-detect | `GITHUB_FULL`, `GITHUB_STANDARD`, or `LOCAL_ONLY` |
| Delivery batching | Phase-first | Issues track tasks; PRs integrate coherent task batches |
| Adaptive control | Enabled | Drift thresholds: annotate=20%, replan=40%, rescope=60% of phase tasks |

**Canonical references** (each topic has exactly one home — cite it, never re-explain it):

| Reference | Owns |
|:----------|:-----|
| `references/behavioral-rules.md` | All behavioral rules (1-25) |
| `references/github-integration.md` | Tracking modes, pre-flight check, all `gh` commands and Issue/PR body templates |
| `references/adaptive-control.md` | Telemetry collection, drift calculation, response actions, state storage, controller activation |
| `references/parallel-protocol.md` | Dispatch/review admission (tiers), lane/worktree protocol, review loop, merge risk, post-integration checks |
| `references/super-philosophy.md` | S.U.P.E.R principles + the 10-check review checklist |
| `references/domain-modeling.md` | Domain surfaces, evidence-driven terminology, one-decision-at-a-time refinement, glossary/ADR write-back |
| `references/wayfinding.md` | Conditional decision map for efforts whose route is still too foggy for Phase 2 confirmation |
| `references/decomposition-strategy.md` | Vertical tracer slices, prefactoring boundaries, and expand-contract for wide refactors |
| `references/templates/` | Schemas for every generated document (analysis, plan, progress, governance, archive) |

**Task tracking modes** (capabilities differ; detection and upgrade instructions live in `references/github-integration.md` § "Pre-flight Check"):

- **GITHUB_FULL**: Issues + Milestones + Labels + Project board + worktrees + batch PRs
- **GITHUB_STANDARD**: same minus the Project board
- **LOCAL_ONLY**: original local-file workflow, no GitHub dependency

## When Not to Use

Do not use this workflow for small scoped fixes, single-file edits, or changes that can be implemented cleanly without a project-wide planning pass. Use `tav-workflow` for those cases instead.

### Escalation Signals

Keep this list in sync with `tav-workflow` § "L2 Escalation Signals" — both skills must apply the same test. Route to `spec-driven-develop` only when **at least two** of these hold; otherwise stay with `tav-workflow`:

- The change spans 3+ modules/subsystems, or breaks a public API/schema contract.
- The work will realistically span multiple sessions or exceed ~10 files.
- Architectural decisions are required (layering, dependency direction, technology selection).
- Acceptance criteria cannot be defined within a single Thinker-Actor-Verifier cycle.

A refactor confined to one module — however messy — is TAV territory, not spec-driven territory.

## Before You Begin: Cross-Conversation Continuity Check

**CRITICAL**: Before starting any phase, inventory and read any existing project-level instruction and memory surfaces (`AGENTS.md`, `CLAUDE.md`, existing platform rule files, the active agent's native project memory, any repo-local fallback memory file already declared by the project or by an existing `docs/progress/MASTER.md`).

Then check if `docs/progress/MASTER.md` already exists:

- If it **exists**: Read it immediately. You are resuming an in-progress task. Identify the tracking mode, current phase, and completed work; continue from the exact point where the previous conversation left off. Do NOT restart from Phase 0.
  - **In GitHub modes**: Also query GitHub for the latest task status — see `references/github-integration.md` § "Reading Progress from GitHub". Update MASTER.md if GitHub state is ahead of the local index.
- If it **does not exist**: This is a fresh start. Proceed to Phase 0.

After loading your current state, populate the platform's native task tracking tool (e.g. TodoWrite) with the active phase's pending tasks: content = task description, status = in-progress for the active task, priority mapped P0=high, P1=medium, P2=low. If no native task tool is available, skip this step — MASTER.md alone is sufficient.

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
   - **Module Inventory**: each module's responsibility, public API surface, size, dependencies — evaluated against all five S.U.P.E.R principles with a per-principle compliance rating
   - **Risks, Tests, Domain & Governance**: transformation risks, complexity hotspots, coding conventions, test coverage, domain glossaries/ADRs and terminology contradictions, instruction/memory surfaces — plus a S.U.P.E.R Architecture Health Summary with violation hotspots (priority targets for the plan)

   Give each agent the Phase 0 direction AND `references/super-philosophy.md`. If sub-agents are unavailable, perform the same analysis sequentially yourself.

   **Scale the analysis to the repository.** The three-agent split above assumes each agent can deep-read its focus area. For large codebases (roughly 100+ modules or beyond ~200k LOC), partition the repository by subsystem (top-level directory or build unit), launch one Module Inventory agent per partition alongside the Architecture and Risk agents, and merge partition outputs into a subsystem-level rollup in `module-inventory.md`. Whatever the strategy, every analysis document must mark areas that were not deep-read with `coverage: shallow` — Phase 3 treats estimates for shallow-coverage areas as low-confidence and prefers smaller task granularity there.

2. Consolidate outputs, resolve contradictions, and write `docs/analysis/` documents from `references/templates/analysis.md`:
   - `project-overview.md` — Architecture, tech stack, entry points, build system, domain-model baseline
   - `module-inventory.md` — Every module with: responsibility, dependencies, size, complexity rating, **S.U.P.E.R compliance score per module**, and a coverage marker (`deep` or `shallow`); large repositories add a subsystem-level rollup section
   - `risk-assessment.md` — Technical risks, compatibility risks, complexity hotspots, testing gaps, project governance gaps, **S.U.P.E.R Architecture Health Summary with violation hotspots**

3. **GitHub Pre-flight Check**: detect the tracking mode per `references/github-integration.md` § "Pre-flight Check". Report the detected mode; if it differs from user expectation, explain how to upgrade (e.g., `gh auth refresh -s project`).

**Output**: Complete `docs/analysis/` (three documents) + detected tracking mode. The S.U.P.E.R assessment is the architectural baseline for all subsequent phases.

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
2. Read `references/domain-modeling.md`, which owns the evidence, one-active-decision, glossary, and ADR rules. Resolve blocking terminology or domain-boundary conflicts before freezing scope and return links to any confirmed write-back.
3. Ask **targeted questions grounded in the analysis** — specific and informed, not generic (e.g., about circular dependencies found, hardcoded environment assumptions, missing interface contracts). At minimum confirm:
   - **Scope** — which modules from the inventory are in scope
   - **Target** — target technology/architecture/state
   - **Constraints** — timeline, backward compatibility, libraries, deployment targets
   - **Priorities** — performance, maintainability, feature parity (use the risk assessment)
   - **S.U.P.E.R priorities** — which violations to fix now vs. defer
   - **Testing policy** — which test layers protect changes; whether to establish a minimal test harness if none exists
   - **Project governance** — canonical instruction surfaces; native memory surface or explicitly named repo fallback

4. Summarize the refined understanding, including resolved domain terms/decisions and any deferred ambiguity, then get explicit confirmation.

**Output**: The authoritative, confirmed task definition guiding Phases 3-6, plus any glossary/ADR updates made through `references/domain-modeling.md`.

---

## Phase 3: Task Decomposition

**Goal**: Break the transformation into manageable, trackable tasks organized in phases, with parallel lanes and coherent delivery batches.

**Actions**:

1. Launch `task-architect` sub-agents with the full Phase 1 analysis AND the confirmed Phase 2 definition. If multiple strategies are plausible, launch 2 agents exploring different approaches (e.g., bottom-up vs. strangler fig) and pick the better result. If sub-agents are unavailable, decompose yourself.
2. Apply `references/decomposition-strategy.md` before assigning phases, lanes, or delivery batches. It owns behavior-slice defaults, expand-contract, operational-task categories, exception rationales, and genuine-blocker rules; record the selected delivery shape on every task card.
3. The decomposition must produce:
   - **Phases** ordered by dependency; early phases prioritize fixing S.U.P.E.R violation hotspots before new features.
   - **Tasks**, each with: description, priority (P0/P1/P2), effort (S/M/L/XL), dependencies, S.U.P.E.R design drivers, acceptance criteria, test expectation, and memory/governance impact. Every task's acceptance criteria implicitly include passing the S.U.P.E.R Quick Check for its listed principles.
     - **Testing is default**: tasks changing user-visible features, behavior, API contracts, schemas, migrations, parsing, routing, permissions, caching, or persistence MUST add or update automated tests; documentation/config tasks may mark tests N/A with an explicit reason.
     - **Governance is default**: tasks introducing a stable rule, gotcha, or convention must include updating the resolved memory surface (and instruction surfaces if the rule affects future agents).
   - **Parallel execution lanes** per phase: group mutually independent tasks; assess merge risk (file overlap).
   - **Delivery batches** per `references/behavioral-rules.md` rule 17: assign every task to exactly one batch and record ID, goal, task IDs, execution waves, lanes, integration branch, combined validation, dependency order, shared contracts, and split rationale.
   - **Dependency graph** as a Mermaid diagram (subgraphs for batch boundaries and lanes) and **milestones** at phase boundaries. Every milestone criterion must be a runnable command or concretely observable check; each phase ends with a milestone acceptance task that runs the combined regression and blocks closure on failure.
4. Write `docs/plan/` documents from `references/templates/plan.md`: `task-breakdown.md`, `dependency-graph.md`, `milestones.md`.
5. **GitHub Resource Synchronization**: capability detection is read-only. Create Labels → Milestones → Issues → [GITHUB_FULL only] Project board only after explicit GitHub tracker-write authorization, using the exact commands and Issue body template in `references/github-integration.md`. Add a 1-second delay between Issue creations and record all URLs plus the Task → Issue → Delivery Batch mapping for Phase 4. If authorization is not granted, select `LOCAL_ONLY` for this run; Issue creation never implies commit, push, or PR authorization.
6. **Initialize Adaptive Control State**: for each Milestone, compute percentage-based drift thresholds and append the adaptive YAML block per `references/adaptive-control.md` § "Adaptive State Storage". In LOCAL_ONLY mode, the state goes to MASTER.md in Phase 4 instead.

**Output**: Complete `docs/plan/` (three documents); in GitHub modes, all tasks exist as labeled, milestoned Issues with adaptive state initialized.

---

## Phase 4: Progress Tracking Documentation

**Goal**: Create a progress tracking and governance system that survives across conversations.

**Actions**:

Use `references/templates/progress.md` for progress documents and `references/templates/governance.md` for governance records.

### Project Governance Surface (all modes)

1. **Inventory existing surfaces**: shared instruction files (`AGENTS.md` or equivalent), `CLAUDE.md`, existing platform rule files, the agent's native project memory, and repo-local fallback memory files only if they already exist or the user explicitly selects one.
2. **Update instruction surfaces without overwriting**: shared cross-agent rules → `AGENTS.md`; Claude Code-specific → `CLAUDE.md`; platform rule files only when they already exist or are requested. Preserve user-written sections, local commands, and security constraints. If an existing rule conflicts with the plan, do not silently replace it — record the conflict in MASTER.md and ask the user at the next checkpoint.
3. **Resolve the memory surface**: prefer native project memory; never silently create a Markdown memory file; use a repo-local fallback only on user confirmation or existing project declaration. Record the resolution in MASTER.md "Governance Status".

Do not create competing truth sources.

### In GITHUB_FULL or GITHUB_STANDARD mode:

1. Create `docs/progress/MASTER.md` as a **lightweight GitHub index**: task name/description, tracking mode, repository, Project URL (GITHUB_FULL), links to analysis/plan documents, milestone table, Issue mapping table (Task → Issue → Batch → PR → status), delivery batch table, "Quick Status Commands", "Current Status", "Next Steps". Do NOT duplicate task details — those live in GitHub Issues.
2. Add an "Execution Telemetry" reference noting where telemetry and drift state live per `references/adaptive-control.md` § "Adaptive State Storage" (Issue comments + Milestone descriptions).
3. Per-phase detail files are optional and lightweight (Issue references only).

### In LOCAL_ONLY mode:

1. Create `docs/progress/MASTER.md`: task name/description, `LOCAL_ONLY` mode, links to analysis/plan documents, phase summary table, links to phase files, "Current Status", "Next Steps".
2. Create one `docs/progress/phase-N-<short-name>.md` per phase: checkbox tasks with inline acceptance criteria plus a "Notes" section.
3. Add the "Adaptive Control State" section and a "Task Telemetry Log" table to MASTER.md per `references/adaptive-control.md` § "Adaptive State Storage".

### Common to all modes:

- Phases use `- [ ] Phase N: <name> (0/X tasks)` linking to the phase file (LOCAL_ONLY) or milestone URL (GitHub modes); `- [x] Phase N: <name> (X/X tasks)` when done.
- "Current Status" is updated at the start and end of each work session.
- Keep full telemetry, Issue-mapping, and batch rows only for the active phase. When a phase closes, collapse them into one summary line (task count, total drift, effort accuracy) and move detail to the phase file (LOCAL_ONLY) or leave it on GitHub; MASTER.md must remain readable in one screen on large projects.

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

1. **Process each phase sequentially.** Before editing, read every open Issue in the phase and revalidate the planned batches against current dependencies, affected files, review scope, and repository rules. If the mapping must change, update `task-breakdown.md`, MASTER.md, and the `Delivery Batch` field in every affected Issue body; comment the regrouping reason so all execution surfaces agree.

2. **Choose the execution tier for each delivery batch** per the admission criteria in `references/parallel-protocol.md` § "Dispatch Admission (Tiered Execution)":
   - **Tier 0 — orchestrator-direct (default)**: S/M effort, ≤ 3 files, context already held, or machine-verifiable acceptance. Execute directly on the batch integration branch. No sub-agents, no worktrees.
   - **Tier 1 — single coder**: L/XL bundles or context-heavy exploration. Delegate the complete batch to one `task-executor`.
   - **Tier 2 — parallel lanes**: only when ALL hold — disjoint lane file sets, ≥ L effort per lane, independent verifiability, ≤ 4 lanes, and confirmed explicit branch/worktree plus commit authorization. Launch one `task-executor` per dependency-ready lane in isolated worktrees, in waves, each with the full batch context plus its task/Issue subset. Without both authorizations, use Tier 0 or Tier 1 on the current/integration worktree. Lane agents never create PRs.
   - Branch convention: repository's own; otherwise `batch/{batch_id}-{slug}` (integration) and `work/{batch_id}-{lane_id}-{slug}` (Tier 2 lanes only).

3. **Review before integrating** per `references/parallel-protocol.md` § "Review Admission (Tiered Review)":
   - **L1 — machine validation (always)**: every task's targeted checks plus the batch's combined validation.
   - **L2 — orchestrator diff review (default)**: after L1, personally read the diff through separate Standards (repository rules first; generic smells only as heuristics) and Spec (missing/partial behavior, scope creep, semantic mismatch) axes against every Issue's acceptance criteria. Never merge the axes into one score.
   - **L3 — independent reviewer (reserved)**: one `code-reviewer` per lane, mandatory for Tier 2 lanes and high-risk work (contract/port formats, logic code, cross-surface semantic invariants). It reruns machine gates and reports Standards and Spec separately. The two axes may use separate agents only when the independence benefit justifies their cold-start cost. Verdict APPROVED | FIXED | ESCALATE; integrate only APPROVED or FIXED lanes; resolve ESCALATE yourself, with the user when needed.
   - Writer model: reviewers never write GitHub state, MASTER.md, drift state, or instruction/memory surfaces. You remain the acceptance-verification authority and single writer for all shared state.
   - Authority: executor and reviewer commits are permitted only when you have confirmed and relayed explicit commit authorization. Commit authorization does not grant branch creation, push, PR creation, or Issue/Milestone/Project writes; follow the independent gates in `references/github-integration.md`.

4. **After each task completion** — follow `references/adaptive-control.md` § "Controller Activation": collect telemetry, update cumulative `drift_score`, write telemetry to the Issue (GitHub modes) or MASTER.md (LOCAL_ONLY), and execute automatic threshold responses. For parallel lanes, lane agents return per-task telemetry and you record it once during batch integration.

Every task card runs as one TAV cycle (Thinker → Actor → Verifier), even when several tasks share a batch or lane. Keep task-level plans, acceptance verdicts, and execution signals distinct; load `tav-workflow` when available, otherwise use the equivalent discipline embedded in `task-executor`. See § "Boundary with TAV".

5. **Integrate and validate each delivery batch** per `references/github-integration.md` § "Delivery Batch Execution Workflow":
   - Consolidate reviewed lane branches onto the batch integration branch; reconcile overlaps.
   - Run per-task checks plus combined validation and post-integration architecture checks.
   - Verify every included Issue's acceptance criteria yourself (L2). Keep incomplete Issues out of closing keywords.
   - When commit, push, and PR authorization are all explicit, create exactly one batch PR with one `Closes #N` per completed Issue. Immediately write the PR number and `in review` state to the batch row and every completed Issue row in MASTER.md; keep partial Issues open with explicit partial status. Without those authorizations, stop after local integration validation and report the ready branch/diff without remote writes.
   - A single-Issue PR is allowed only for a documented exception or a one-Issue phase.

6. **Progress updates**:
   - **GitHub modes**: merged batch PRs auto-close their Issues; update MASTER.md "Current Status", "Issue Mapping", "Delivery Batches".
   - **LOCAL_ONLY**: check off tasks in phase files; update MASTER.md counts.
   - **All modes**: durable knowledge → resolved memory surface; agent-behavior changes → resolved instruction surfaces.

7. **At each phase boundary**: the phase's milestone acceptance task must pass before the phase closes — a failure there is a gate failure (return to the offending batch or task, or trigger adaptive replan if it reveals plan-level drift). Close the Milestone only after it passes.

8. **When all tasks are complete** (all Issues closed or all checkboxes checked): proceed to Phase 6 (Archive).

**Output**: All planned tasks implemented and verified.

---

## Phase 6: Archive

**Trigger**: All tasks complete — all Issues closed (GitHub modes) or all checkboxes `[x]` (LOCAL_ONLY).

**Goal**: Archive all workflow artifacts for traceability, then clean up working directories.

**Actions**:

1. Announce completion to the user.
2. Determine the archive directory name from the Phase 2 task name (lowercase, hyphens, no special characters): `docs/archives/<project-name>/`. Target structure and index template: `references/templates/archive.md`.
3. Move `docs/analysis/`, `docs/plan/`, and `docs/progress/` into the archive; copy snapshots or export references for the resolved instruction and memory surfaces into `docs/archives/<project-name>/governance/`; move any other temporary workflow files.
4. **[GitHub modes]** With explicit GitHub tracker-write authorization, close each phase's Milestone (if not already closed) and optionally close the Project board. Otherwise leave remote state unchanged and record the pending archive synchronization locally.
5. Create or update `docs/archives/README.md` with an entry: project name, one-line description, date range, link to archived MASTER.md, and (GitHub modes) the Project URL.
6. Remove the now-empty `docs/analysis/`, `docs/plan/`, `docs/progress/` directories. Keep active instruction and memory surfaces in place; only their snapshots live under the archive.
7. **Estimation calibration retrospective**: aggregate the telemetry log's effort deltas by task type and module. Where a category shows systematic underestimation (average delta ≥ +1 across 3+ tasks), distill 1-3 calibration rules (e.g. "schema-touching tasks in this repo run one effort level above estimate") and record them through the knowledge consolidation pipeline to the resolved memory surface — the next project starts from calibrated priors instead of zero.

8. Suggest the user commit the archive to version control.

**Output**: All artifacts under `docs/archives/<project-name>/` with an updated `docs/archives/README.md` index.

---

## Boundary with TAV

Spec-Driven Develop owns analysis, decomposition, delivery-batch orchestration, and progress scaffolding. `tav-workflow` owns the scoped implementation loop: during Phase 5b, one TAV cycle executes exactly one task card, while the enclosing batch coordinates shared branches, integration validation, and PR creation. This contract is mirrored in `tav-workflow` § "Operating Inside a Spec-Driven Project" — keep both sides in sync.

### Handoff Contract (per task)

**Input mapping — what each task card gives the TAV cycle:**

| Task card field (Issue / task-breakdown.md / executor input) | TAV consumer |
|:-------------------------------------------------------------|:-------------|
| Task description | Thinker task definition (`user_request`) |
| Acceptance criteria + test expectation | Baseline of the Thinker verification plan |
| S.U.P.E.R design drivers | Additional Verifier check items |
| Relevant files / dependencies | Starting points for Thinker evidence gathering |
| Memory/governance impact | Pre-declared candidates for the cycle's Phase 4 knowledge consolidation |

**Write-back mapping — what the finished TAV cycle returns:**

| TAV outcome | Spec-Driven update |
|:------------|:-------------------|
| Verifier pass | Mark the task ready for batch integration; after integrated validation, close it through the batch PR's `Closes #N` line or check the LOCAL_ONLY checkbox; update MASTER.md status |
| TAV execution signals (rework iterations, Thinker returns, unplanned files touched) | Post-task telemetry: effort level and unplanned-dependency count (see `references/adaptive-control.md` § "Telemetry Collection") |
| Knowledge consolidation captures (at most 1-3 durable rules per cycle) | Written to the surfaces resolved under "Governance Status" in MASTER.md — durable facts to the memory surface, agent-behavior rules to the instruction surfaces (fulfills Phase 5b progress write-back) |
| `[PUA-REPORT]` or blocked state | Issue comment (or phase-file note); counts toward drift annotation |

**State ownership:** `docs/progress/MASTER.md` (plus GitHub Issues) is the only project-level authority. `.tav/state.json` is scoped to one task: it is created only when that single task needs cross-session recovery, it is archived or deleted when the task completes, and it never carries project-level progress.
