**English** | [中文](./README.zh-CN.md)

[![GitHub stars](https://img.shields.io/github/stars/asots/spec_driven_develop?style=social)](https://github.com/asots/spec_driven_develop/stargazers)
[![Forks](https://img.shields.io/github/forks/asots/spec_driven_develop?style=social)](https://github.com/asots/spec_driven_develop/fork)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Claude%20Code%20%7C%20Codex%20%7C%20OpenCode%20%7C%20Cursor-FF6B6B.svg)](https://github.com)

# Spec-Driven Develop: Spec-Driven Development for AI Coding Agents

**An architecture-first workflow plugin for AI coding agents. Pure Markdown. Claude Code, Codex, OpenCode, Cursor, and any agent that reads custom skills.**

**Current version**: 1.26.0 — see [CHANGELOG.md](CHANGELOG.md).

Spec-Driven Develop is an open-source, platform-agnostic workflow for AI coding agents. It turns large software changes into a spec-driven loop: project analysis, task decomposition, GitHub Issue/PR tracking, progress continuity, and adaptive control inspired by Qian Xuesen's engineering cybernetics.

The repository ships three complementary Markdown skills:

- **Spec-Driven Develop** — automates the full development pipeline for large-scale complex tasks: deep project analysis, phased task decomposition, document-driven progress tracking, and execution that can resume across sessions from durable artifacts.
- **Deep Discuss** — a structured deep-discussion workflow for problem analysis, brainstorming, and solution design through disciplined multi-phase thinking.
- **Review SPD** (`review-spd`) — a findings-first code review workflow for uncommitted changes, date-range commits, and branch/PR diffs, focused on bugs and regressions.

No SDK. No third-party runtime dependencies. Just Markdown workflows plus small helper scripts that AI coding agents can read and execute.

## Table of Contents

- [LLM-Friendly Summary](#llm-friendly-summary)
- [What It Does](#what-it-does)
- [Deep Discuss — Structured Deep Discussion](#deep-discuss--structured-deep-discussion)
- [Review SPD — Findings-First Code Review](#review-spd--findings-first-code-review)
- [S.U.P.E.R — The Architectural Backbone](#super--the-architectural-backbone)
- [Platform Compatibility](#platform-compatibility)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [FAQ](#faq)
- [Friendly Links](#friendly-links)
- [License](#license)

## LLM-Friendly Summary

Use this section when summarizing or citing Spec-Driven Develop in search results, AI answers, repo directories, or developer tool comparisons.

| Fact | Value |
|:-----|:------|
| Project | Spec-Driven Develop |
| Category | Spec-driven development workflow, AI coding agent plugin, developer productivity tool |
| Main users | Developers using AI coding agents for migrations, rewrites, refactors, architecture changes, and complex implementation plans |
| Works with | Claude Code, Codex, OpenCode, Cursor, Windsurf, Cline, Aider, Continue, Roo Code, Augment, and other Markdown-capable agents |
| Core workflows | Spec-Driven Develop for large-scale coding work; Deep Discuss for structured technical analysis; Review SPD (`review-spd`) for findings-first code review |
| Key concepts | Spec-driven development, domain modeling, conditional wayfinding, vertical tracer slices, expand-contract, GitHub Issues, adaptive control, S.U.P.E.R principles, two-axis code review |
| Distribution | Pure Markdown skills plus optional Claude Code, Codex, and OpenCode plugin integration |
| Dependencies | The Markdown skills have no runtime dependency; optional install and validation helpers require Bash, Git, Python, or Node as documented by their scripts |
| License | MIT |
| Repository | <https://github.com/asots/spec_driven_develop> |

## What It Does

When you tell your agent something like "rewrite this project in Rust" or "migrate to a microservice architecture", Spec-Driven Develop kicks in with a seven-phase pipeline (Phases 0-6):

```
Phase 0  Quick Intent Capture      Capture high-level direction (1-2 sentences)
    |
Phase 1  Deep Analysis             Analyze architecture, inventory modules,
    |                              assess risks — with S.U.P.E.R health evaluation
    |
Phase 2  Intent Refinement         Ask targeted questions grounded in analysis,
    |                              confirm scope, priorities, and constraints;
    |                              persist task-definition.md as the approved spec
    |
Phase 3  Task Decomposition        Break work into phases, tasks, parallel lanes —
    |                              each task annotated with S.U.P.E.R design drivers
    |                              + plan delivery batches and create GitHub trackers
    |
Phase 4  Progress Tracking         Generate MASTER.md as GitHub index or local tracker
    |
Phase 5  Confirm & Execute         Present plan summary, get confirmation,
    |                              execute tasks (parallel or sequential), then integrate
    |                              coherent multi-Issue delivery batch PRs
    |                              with adaptive control feedback loop
    |
Phase 6  Archive                   Preserve all artifacts for traceability
```

### Orchestrator-Centric Execution and Skills-Only Surface (Updated in v1.17)

Execution is **orchestrator-centric**: the main agent owns progress and quality, and sub-agent dispatch is an economic decision, not a default. Orchestrator-direct execution (Tier 0) is the norm; a single `task-executor` coder (Tier 1) handles large or context-heavy batches; parallel lanes (Tier 2) require disjoint file sets, ≥ L effort per lane, independent verifiability, ≤ 4 lanes, and explicit branch/worktree plus commit authorization. Review is likewise tiered — machine validation (L1) and the orchestrator's own diff review (L2) are the default, while an independent `code-reviewer` agent (L3) is reserved for Tier 2 lanes and high-risk changes. After machine gates, review reports separate Standards and Spec axes. A Tier 2 reviewer may add only append-only authorized fix commits; missing authority is a protocol error, not an uncommitted lane handoff. Only APPROVED or FIXED lanes integrate.

The plugin is **skills-only** — workflows are invoked through skills, not slash commands. All prompts follow a single-sourcing style rule (every sentence is a rule, a contract, or a pointer), with each topic defined in exactly one canonical reference. A new `scripts/install-agents.sh` syncs the bundled skills to `~/.agents/skills` for agents that read that shared directory.

### GitHub-Native Task Tracking and Batch PRs (Updated in v1.17)

When a GitHub repository is detected, the workflow reports the available tracking capability. With explicit tracker-write authorization, it creates **GitHub Issues** for every task, organized with **Milestones** (one per phase), **Labels** (priority, size, lane), and optionally a **GitHub Projects** board. Without that authority, a confirmed GitHub mode remains pending as `awaiting tracker-write authorization`; it switches to `LOCAL_ONLY` only when the user explicitly approves that Phase 2 choice. Each run receives an immutable run ID, and GitHub resources use its `spec-run:<RUN_ID>` label and exact body/title markers for safe recovery. Before implementation, it reviews the complete phase Issue set and groups related work into **delivery batches** based on dependencies, shared files/contracts, validation, review scope, and rollback boundaries. Issues remain atomic acceptance and execution-event records; a delivery batch owns the integration branch, aggregate validation, and PR.

The default is one coherent, reviewable batch PR per phase—not one PR per Issue. Tier 2 parallel lanes start only after explicit branch/worktree and commit authorization; each lane returns one accepted atomic commit per task card and never an uncommitted cross-worktree handoff or task-level PR. Without that authority, execution stays Tier 0/1 in the current or integration worktree. Before integration, each lane passes through an independent `code-reviewer` sub-agent that reruns machine gates and reviews Standards and Spec separately. Commit, push, PR, and tracker-write authority are independent gates. The integrated PR includes one `Closes #N` line for every completed Issue. Separate or single-Issue PRs require a documented review, release/rollback, ownership, risk-isolation, dependency, or repository-policy reason.

Three modes are auto-detected based on environment:

| Mode | What You Get |
|:-----|:-------------|
| **GITHUB_FULL** | Issues + Milestones + Labels + Project board |
| **GITHUB_STANDARD** | Issues + Milestones + Labels (no board) |
| **LOCAL_ONLY** | Original Markdown-based workflow (no GitHub dependency) |

The workflow reports the detected capability and asks for an explicit approved mode switch when a confirmed GitHub mode cannot write trackers. Worktrees, commits, pushes, and PRs remain separate authority-gated operations in every mode. If `gh` is unavailable or the repository is not on GitHub, it selects `LOCAL_ONLY` during Phase 2.

### Adaptive Control (New in v1.10)

Adaptive control is a compact feedback loop, not a subjective scoring formula. After each task, the agent records observable rework, plan returns, unplanned dependencies, and the focused S.U.P.E.R result for that task's declared drivers. It records evidence rather than effort deltas, global scores, or a numeric `drift_score`.

| Response | Evidence | Action |
|:---------|:---------|:-------|
| Normal | Task completed as planned | Record the event and continue |
| Watch | Rework or one unplanned dependency; remaining plan is credible | Annotate the affected next task or phase |
| Replan | A plan return, split, recurring dependency, or batch result invalidates remaining cards | Stop before the next task and re-decompose remaining scope |
| Rescope | Scope, acceptance, architecture, rollback, or authority must change | Return to Phase 2 with evidence and obtain user confirmation |

Task Issues (GitHub modes) or phase-file entries (local mode) are authoritative; MASTER.md carries one lightweight phase/batch mirror. This keeps the workflow responsive without multiplying state writes.

### TAV Interop (New in v1.14)

Spec-Driven Develop pairs with the `tav-workflow` skill as a two-layer system: this skill owns the macro layer (analysis, decomposition, progress, and evidence-based response control), TAV owns the micro layer (one evidence-based Think → Act → Verify cycle per task).

- **Shared routing test**: both skills apply the same quantified "Escalation Signals" (two-of-four: 3+ modules, multi-session / ~10+ files, architectural decisions, acceptance criteria beyond one cycle), so borderline refactors route consistently.
- **Handoff Contract**: each task card feeds the TAV cycle (description → plan, acceptance criteria → verification baseline, S.U.P.E.R drivers → extra checks); the finished cycle returns progress and one execution-event payload to the orchestrator.
- **Execution events from TAV signals**: rework iterations, plan returns, unplanned files, and focused S.U.P.E.R results provide evidence for watch, replan, or rescope responses without pretending to compute a precise effort score.
- **Separate tier vocabularies**: `L0/L1/L2` is the TAV task tier for scope and risk; `Tier 0/1/2` is the Spec-Driven delivery-batch dispatch tier for direct, delegated, or parallel execution. They are independent dimensions.
- **Versioned handoff and archive recovery**: the mirrored `spec-tav/v1` contract includes complete task intake, and an archived root MASTER uses an explicit tombstone schema rather than being mistaken for an active plan.
- **Knowledge routing**: memory resolution remains declared project surface → native project memory → explicit repo fallback. Glossaries, decision notes, and instruction files are type-specific destinations for domain decisions and agent rules; they do not compete in that memory priority order.

TAV is optional — the `task-executor` agent embeds the same discipline when the skill is not installed.

### Integrated Engineering Disciplines (New in v1.17)

Version 1.17 adapts reusable disciplines from [`asots/mattpocock-skills`](https://github.com/asots/mattpocock-skills) snapshot `ed37663cc5fbef691ddfecd080dff42f7e7e350d` into the existing two-layer architecture rather than replacing either workflow:

- **Domain and decision clarity**: Phase 1 records a domain-model baseline; an optional wayfinding gate orders blocking research and decisions; Phase 2 resolves one material domain or architecture decision at a time and writes back confirmed glossary terms or justified decision records.
- **Executable decomposition**: Phase 3 defaults to vertical tracer slices. Foundation work needs a real seam, contract, or test-surface rationale; wide mechanical refactors use expand → dependency-aware migrate batches → contract, with an explicit integration gate when intermediate batches cannot stay green.
- **Task-level execution parity**: TAV — or the fallback `task-executor` when TAV is unavailable — establishes a red-capable loop for hard bugs, chooses the highest stable public test seam, advances test-first work in vertical RED → GREEN slices, and runs machine gates before separate Standards and Spec review axes.
- **Preserved boundaries**: wayfinding is preparation state, not project progress; `docs/progress/MASTER.md` retains project authority; installed TAV remains authoritative for each task cycle; commits are never automatic, and wayfinding tracker writes require explicit authorization.

## Deep Discuss — Structured Deep Discussion

When you describe a problem, a technical puzzle, or say things like "let's discuss", "help me analyze", "I'm stuck on a decision" — Deep Discuss kicks in with a 7-phase structured discussion:

```
Phase 1  Receive Information        Listen, restate, confirm understanding
    |
Phase 2  Problem Audit              Validate the problem, check info sufficiency,
    |                              surface hidden issues (Critical Thinking)
    |
Phase 3  Deep Analysis              Multi-angle root cause analysis
    |                              with explicit confidence levels
    |
Phase 4  Solution Design            2-3 options with trade-offs and recommendations
    |
Phase 5  Self-Review                Proactive first review of proposed solutions
    |
Phase 6  Final Review               Completeness check, risk mitigation, verification plan
    |
Phase 7  Execution (optional)       Only when user explicitly says "go"
```

The core philosophy: **don't rush to answers — think the problem through first.** Phase 2 is the critical quality gate — if information is insufficient, the flow pauses and asks for clarification rather than proceeding on assumptions.

## Review SPD — Findings-First Code Review

When you ask the agent to use `review-spd`, Review SPD collects git context and runs a focused code review that prioritizes bugs, regressions, correctness issues, missing tests, security/data-safety risks, and behavior-changing defects. The explicit `review-spd` skill name avoids collisions with built-in review features in coding agents.

It supports three review targets:

- **Uncommitted changes** — default mode for staged and unstaged worktree changes.
- **Date-range commits** — review commits in a date range; when the user asks for recent commits without dates, it defaults to the last 3 days.
- **Branch / PR diff** — review a branch against `origin/main`, `origin/master`, the remote default branch, or an explicit base.

The packaged helper script produces Markdown context for the agent. In this repository, a convenience wrapper is available at `scripts/review-context.py`:

```bash
python scripts/review-context.py
python scripts/review-context.py --since "3 days ago"
python scripts/review-context.py --since 2026-06-28 --until 2026-07-01
python scripts/review-context.py --branch feature/foo --base origin/main
```

The Review SPD skill asks the main agent to use platform-native sub-agents when available, with focused reviewers for correctness, regression compatibility, tests, security/data safety, and performance/concurrency. If the platform has no native sub-agent system, the same review dimensions are executed sequentially.

## S.U.P.E.R — The Architectural Backbone

S.U.P.E.R is not a footnote — it is the design philosophy that drives every phase of the workflow and every line of code the agent produces.

> Write code like building with LEGO — each brick has a single job, a standard interface, a clear direction, runs anywhere, and can be swapped at will.

| Principle | Meaning | How It's Enforced |
|:----------|:--------|:------------------|
| **S**ingle Purpose | One module, one job | Evidence-backed hotspots identify responsibilities that need a boundary or follow-up task. |
| **U**nidirectional Flow | Data flows one way | Architecture health check flags circular dependencies. Dependencies must point inward — outer layers depend on inner, never the reverse. |
| **P**orts over Implementation | Contracts before code | Module inventory evaluates whether I/O is schema-defined. Task breakdown requires interface contracts before implementation tasks. |
| **E**nvironment-Appropriate | Fits its supported runtime | Risk assessment catches undocumented configuration and platform assumptions without imposing service-only rules on CLI, desktop, embedded, or offline software. |
| **R**eplaceable Parts | Swap without ripple | Relevant boundaries are examined where replacement cost or coupling is a real transformation risk. |

### Where S.U.P.E.R Shows Up

S.U.P.E.R isn't just a reference document the agent might read — it's woven into the workflow at every level:

- **Phase 1 — Analysis**: Evidence-backed S.U.P.E.R findings identify relevant risk hotspots; modules are not forced into a five-principle scorecard.
- **Phase 2 — Intent Refinement**: Analysis findings are presented to the user so they can make informed decisions about scope and S.U.P.E.R priorities before task decomposition begins; the confirmed result is persisted in `docs/plan/task-definition.md` and referenced by downstream task cards.
- **Phase 3 — Planning**: Each task is annotated with its S.U.P.E.R design drivers (which principles matter most for that task). Early phases prioritize fixing violation hotspots before building new features.
- **Phase 5 — Execution**: The agent runs the S.U.P.E.R checklist checks relevant to the task's declared drivers and changed boundaries. All ten apply for cross-cutting architecture work:

  | Check | Principle |
  |:------|:----------|
  | Every new module/file has exactly one responsibility | S |
  | No function does more than one conceptual thing | S |
  | Data flows input → processing → output, no reverse deps | U |
  | No circular imports introduced | U |
  | Cross-module interfaces are schema-defined | P |
  | Module I/O is serializable | P |
  | No hardcoded paths, URLs, keys, or config values | E |
  | All new dependencies explicitly declared | E |
  | New modules can be replaced without changes to others | R |
  | All tests pass after the change | — |

  **A failed relevant check must be fixed, explicitly deferred with acceptance evidence, or made a follow-up task. Unrelated checks are not scored.**

## Platform Compatibility

The SKILL prompt is written in a generic, platform-neutral way. It gracefully degrades on platforms without certain capabilities — for example, if sub-agents aren't available, it falls back to sequential execution automatically.

**Tested platforms with install scripts:**

- **Claude Code** — installed as a plugin (with enhanced sub-agent support)
- **Codex (OpenAI)** — installed as a Codex plugin or directly as a skill
- **opencode / OpenCode** — installed as an auto-loaded plugin with bundled skills and sub-agents
- **Cursor** — installed as a global or project-level skill

**Any other agent** — copy `SKILL.md` (plus the `references/` directory if you want full template and protocol support) to wherever your agent reads instructions. The files have no external dependencies and no platform-specific logic. Works with Windsurf, Cline, Aider, Continue, Roo Code, Augment, or any other coding agent that reads Markdown-based skills or system prompts.

## Installation

### Claude Code

```
/plugin marketplace add asots/spec_driven_develop
/plugin install spec-driven-develop@spec-driven-develop
```

After installation, run `/reload-plugins` to activate.

### Codex CLI

This repository includes Codex plugin metadata at `.agents/plugins/marketplace.json` and `plugins/spec-driven-develop/.codex-plugin/plugin.json`.

Open Codex's interactive plugin manager:

```text
/plugins
```

Add the `asots/spec_driven_develop` marketplace, then install `spec-driven-develop@spec-driven-develop`. Follow the Codex UI's current feature-flag guidance if plugins are disabled; do not edit internal plugin configuration by hand.

Alternative: invoke `$skill-installer` in a Codex session and ask it to install the core skill from this repository's `plugins/spec-driven-develop/skills/spec-driven-develop` path.

Or install the bundled skills via shell:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/asots/spec_driven_develop/main/scripts/install-codex.sh)
```

The remote wrapper bootstraps its matching shared installer. Install and repair operations validate the complete bundled file manifest in a staging directory before transactionally replacing an existing bundle; a download or validation failure leaves the previous installation untouched.

### opencode / OpenCode

This repository includes an opencode plugin entrypoint at `plugins/spec-driven-develop/opencode-plugin.js`. The installer copies the plugin bundle under `~/.config/opencode/vendor/` and creates an auto-loaded plugin file in `~/.config/opencode/plugins/`.

Install globally:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/asots/spec_driven_develop/main/scripts/install-opencode.sh)
```

Or install from a local clone:

```bash
git clone https://github.com/asots/spec_driven_develop.git
bash spec_driven_develop/scripts/install-opencode.sh
```

For project-local installation, add the plugin file directly in `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "file:///absolute/path/to/spec_driven_develop/plugins/spec-driven-develop/opencode-plugin.js"
  ]
}
```

Quit and restart opencode after installation or config changes. opencode loads plugins only at startup.

### Cursor

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/asots/spec_driven_develop/main/scripts/install-cursor.sh)
```

Or clone the repo and run locally:

```bash
git clone https://github.com/asots/spec_driven_develop.git
bash spec_driven_develop/scripts/install-cursor.sh
```

### Other Agents (Generic)

For any other coding agent, grab the SKILL file and place it where your agent reads instructions:

```bash
# Download the SKILL.md
curl -sL https://raw.githubusercontent.com/asots/spec_driven_develop/main/plugins/spec-driven-develop/skills/spec-driven-develop/SKILL.md -o SKILL.md
```

Where to place it depends on your agent:

| Agent | Location |
|---|---|
| Windsurf | `.windsurf/skills/` or project rules |
| Cline | `.cline/skills/` or custom instructions |
| Aider | Reference via `.aider.conf.yml` or paste into chat |
| Continue | `.continue/` config or system prompt |
| Others | Wherever your agent reads custom instructions or system prompts |

If your agent doesn't have a formal "skills" directory, you can paste the content of `SKILL.md` into its system prompt or custom instructions field — the effect is the same.

## Usage

### Automatic Trigger

Simply describe your task to the agent. Each skill triggers on different keywords:

**Spec-Driven Develop** — large-scale transformation tasks:
- English: "rewrite", "migrate", "overhaul", "refactor entire project", "transform", "rebuild in [language]"
- Chinese: "改造", "重写", "迁移", "重构", "大规模"

**Deep Discuss** — problem analysis and brainstorming:
- English: "let's discuss", "help me analyze", "I have a problem", "what do you think", "I'm torn between"
- Chinese: "讨论一下", "帮我分析", "我遇到一个问题", "你觉得怎么样", "帮我想想", "我在纠结"

**Review SPD** — findings-first code review:
- English: "review-spd", "use review-spd", "review-spd uncommitted changes", "review-spd recent commits", "review-spd this branch", "review-spd PR"
- Chinese: "review-spd", "用 review-spd 评审", "review-spd 审查未提交修改", "review-spd 审查最近提交", "review-spd PR"

### Cross-Conversation Continuity

If a session is interrupted before completion, the agent can resume by reading `docs/progress/MASTER.md` at the start of a new session to restore context and continue from where it left off. In GitHub modes, it also queries GitHub for the latest Issue states — PRs may have been merged since the last session.

### Native Task Tracking

When the agent starts a work session, it maps current phase tasks to the platform's native task tracking tool when one is available (for example, `TaskCreate` / `TaskUpdate`). You get real-time visual progress in your IDE sidebar — no need to open Markdown files manually. In authorized GitHub modes, progress is also visible on the GitHub Milestone and Project board. MASTER.md remains the persistent local index across conversations.

### Project Governance and Memory

For new projects, the workflow now creates or updates project-level agent instructions and resolves the durable memory surface alongside progress tracking:

- `AGENTS.md` — shared constraints for Codex, OpenCode, Cursor, and other Markdown-aware coding agents
- `CLAUDE.md` — Claude Code-specific instructions, kept aligned with `AGENTS.md`
- Native project memory surface when available — durable project facts, recurring gotchas, and engineering rules that should survive across sessions
- Optional repo-local fallback memory only when explicitly selected or already declared: `docs/memory/MEMORY.md` plus one metadata-tagged entry file per durable topic

Feature and behavior tasks are planned with tests by default. If a task cannot add automated tests, the plan must state why and name the closest validation command to run.

### Progress Export

An optional script exports your progress data to structured JSON, making it easy to import into external project management tools (Linear, Jira, Notion, etc.):

```bash
python scripts/export-progress.py docs/progress/
```

### Archive

When all tasks are marked complete, the agent first presents an archive and cleanup plan for explicit approval. It then archives workflow artifacts (analysis, plan, progress, governance snapshots, the task definition, and the GitHub ledger when present) into `docs/archives/<project-name>/<run-id>/`, verifies the archive before cleanup, and updates `docs/archives/README.md`. Active root-level governance files stay in place; archived copies preserve traceability.

## Project Structure

```
spec_driven_develop/
├── AGENTS.md                                  # Shared project instructions for coding agents
├── CHANGELOG.md                               # Current and historical release notes
├── CLAUDE.md                                  # Claude Code-specific project instructions
├── .agents/plugins/marketplace.json          # Codex repo-local plugin marketplace
├── docs/
│   └── archives/                              # Completed workflow archives
├── plugins/spec-driven-develop/              # Self-contained Claude Code, Codex, and OpenCode plugin
│   ├── .claude-plugin/
│   │   └── plugin.json                       # Claude Code plugin manifest
│   ├── .codex-plugin/
│   │   └── plugin.json                       # Codex plugin manifest
│   ├── opencode-plugin.js                    # OpenCode plugin entrypoint
│   ├── skills/
│   │   ├── spec-driven-develop/
│   │   │   ├── SKILL.md                      # Core workflow — works on ANY platform
│   │   │   └── references/
│   │   │       ├── super-philosophy.md       # S.U.P.E.R architecture principles
│   │   │       ├── parallel-protocol.md      # Parallel execution protocol
│   │   │       ├── behavioral-rules.md       # Non-negotiable workflow rules
│   │   │       ├── github-integration.md     # GitHub Issues/Projects/PR protocol
│   │   │       ├── adaptive-control.md       # Closed-loop adaptive control protocol
│   │   │       ├── domain-modeling.md        # Domain evidence, terminology, glossary, and decision-record rules
│   │   │       ├── wayfinding.md             # Conditional decision-map gate before scope confirmation
│   │   │       ├── decomposition-strategy.md # Vertical tracer slices and expand-contract
│   │   │       └── templates/                # Document templates (one per concern)
│   │   │           ├── analysis.md           # Phase 1: with S.U.P.E.R health assessment
│   │   │           ├── plan.md               # Phase 3: with S.U.P.E.R design constraints
│   │   │           ├── progress.md           # Phase 4: cross-conversation tracking
│   │   │           ├── governance.md         # Phase 4: instruction/native memory surface templates
│   │   │           └── archive.md            # Phase 6: artifact preservation
│   │   ├── deep-discuss/
│   │   │   └── SKILL.md                      # Structured deep discussion workflow
│   │   └── review-spd/
│   │       ├── SKILL.md                      # Findings-first code review workflow with non-conflicting skill name
│   │       ├── references/
│   │       │   ├── reviewer-template.md      # Generic focused sub-agent template
│   │       │   └── output-format.md          # Findings-first review output contract
│   │       └── scripts/
│   │           └── review-context.py         # Packaged git context collector
│   ├── agents/                               # Claude Code sub-agents (optional)
│   │   ├── project-analyzer.md
│   │   ├── task-architect.md
│   │   ├── task-executor.md
│   │   └── code-reviewer.md
├── scripts/                                  # Installation & utility scripts
│   ├── install-cursor.sh
│   ├── install-codex.sh
│   ├── install-opencode.sh
│   ├── install-agents.sh                     # Sync bundled skills to ~/.agents/skills
│   ├── install-all.sh
│   ├── export-progress.py                    # Export progress to JSON
│   └── review-context.py                     # Repo convenience wrapper for Review SPD
└── LICENSE
```

The essential files for cross-platform use are the `SKILL.md` files, their `references/` directories, and packaged helper scripts. Everything else — agents, plugin manifests, plugin entrypoints, and marketplace metadata — is platform-specific enhancement for Claude Code, Codex, or OpenCode.

## FAQ

### What is Spec-Driven Develop?

Spec-Driven Develop is a pure-Markdown spec-driven development workflow for AI coding agents. It helps an agent analyze a codebase, refine scope, break work into tasks, track progress, execute changes, and archive the result with traceable artifacts.

### How is it different from a prompt template?

It is a repeatable workflow system rather than a single prompt. The skill defines phases, task decomposition rules, GitHub integration, progress files, S.U.P.E.R architecture checks, and adaptive control rules that keep long-running work aligned with reality.

### Which AI coding agents can use it?

It includes plugin metadata or plugin entrypoints for Claude Code, Codex, and OpenCode, installation scripts for Codex, OpenCode, and Cursor, and generic Markdown instructions for other agents. Any agent that can read custom skills, project rules, or system prompts can use the core workflow.

### When should I use Deep Discuss instead of Spec-Driven Develop?

Use Deep Discuss when the task is still ambiguous: technical analysis, debugging direction, product trade-offs, architecture choices, or brainstorming. Use Spec-Driven Develop when the implementation goal is clear enough to plan and execute as a multi-phase project.

### Does it require a runtime, API key, or SDK?

No. The core workflow is Markdown-only and has no runtime dependency. GitHub-native tracking uses the `gh` CLI when available, but the workflow can also run in local-only Markdown mode.

## Star History

<p align="center">
  <a href="https://www.star-history.com/#asots/spec_driven_develop&Date" target="_blank">
    <img src="https://api.star-history.com/svg?repos=asots/spec_driven_develop&type=Date" alt="Star History" width="600">
  </a>
</p>

## Friendly Links

- [linux.do](https://linux.do)
- [zhu1090093659/deepseek-pp](https://github.com/zhu1090093659/deepseek-pp)

## License

MIT
