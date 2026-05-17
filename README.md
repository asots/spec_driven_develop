**English** | [中文](./README.zh-CN.md)

[![GitHub stars](https://img.shields.io/github/stars/zhu1090093659/spec_driven_develop?style=social)](https://github.com/zhu1090093659/spec_driven_develop/stargazers)
[![Forks](https://img.shields.io/github/forks/zhu1090093659/spec_driven_develop?style=social)](https://github.com/zhu1090093659/spec_driven_develop/fork)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Claude%20Code%20%7C%20Codex%20%7C%20Cursor-FF6B6B.svg)](https://github.com)

## Table of Contents

- [What It Does](#what-it-does)
- [Deep Discuss — Structured Deep Discussion](#deep-discuss--structured-deep-discussion)
- [S.U.P.E.R — The Architectural Backbone](#super--the-architectural-backbone)
- [Platform Compatibility](#platform-compatibility)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Friendly Links](#friendly-links)
- [License](#license)

# Spec-Driven Develop

**A structured methodology for AI coding agents. Pure Markdown. Any platform. Architecture-first.**

Spec-Driven Develop is a platform-agnostic AI agent plugin that ships two complementary skills:

- **Spec-Driven Develop** — automates the full pre-development pipeline for large-scale complex tasks: deep project analysis, phased task decomposition, document-driven progress tracking, and task-specific sub-SKILL generation — all before a single line of implementation code is written.
- **Deep Discuss** — a structured deep-discussion workflow for problem analysis, brainstorming, and solution design through disciplined multi-phase thinking.

No SDK. No runtime. No dependencies. Just Markdown files that any AI coding agent can read and execute.

## What It Does

When you tell your agent something like "rewrite this project in Rust" or "migrate to a microservice architecture", Spec-Driven Develop kicks in with a 7-phase preparation pipeline:

```
Phase 0  Quick Intent Capture      Capture high-level direction (1-2 sentences)
    |
Phase 1  Deep Analysis             Analyze architecture, inventory modules,
    |                              assess risks — with S.U.P.E.R health evaluation
    |
Phase 2  Intent Refinement         Ask targeted questions grounded in analysis,
    |                              confirm scope, priorities, and constraints
    |
Phase 3  Task Decomposition        Break work into phases, tasks, parallel lanes —
    |                              each task annotated with S.U.P.E.R design drivers
    |                              + create GitHub Issues, Milestones & Project board
    |
Phase 4  Progress Tracking         Generate MASTER.md as GitHub index or local tracker
    |                              for cross-conversation continuity
    |
Phase 5  Sub-SKILL Generation      Create a project-level SKILL with inlined
    |                              S.U.P.E.R principles and code review checklist
    |
Phase 6  Handoff                   Present all artifacts, confirm readiness
    |
   ...  Development Phases         Iterative implementation with progress tracking
    |
Phase 7  Archive                   Preserve all artifacts for traceability
```

A master progress file (`docs/progress/MASTER.md`) serves as the agent's memory anchor across conversations. No matter how many sessions a task spans, the agent always knows where things stand.

### GitHub-Native Task Tracking (New in v1.9)

When a GitHub repository is detected, the workflow automatically creates **GitHub Issues** for every task, organized with **Milestones** (one per phase), **Labels** (priority, size, lane), and optionally a **GitHub Projects** board. Each task executor works in an isolated **worktree**, creates a **PR** linked to its Issue (`closes #N`), and the Issue auto-closes on merge.

Three modes are auto-detected based on environment:

| Mode | What You Get |
|:-----|:-------------|
| **GITHUB_FULL** | Issues + Milestones + Labels + Project board + worktree + PR |
| **GITHUB_STANDARD** | Issues + Milestones + Labels + worktree + PR (no board) |
| **LOCAL_ONLY** | Original Markdown-based workflow (no GitHub dependency) |

The workflow gracefully degrades — if `gh` CLI is unavailable or the repo isn't on GitHub, it falls back to local-only mode automatically.

### Adaptive Control (New in v1.10)

Inspired by engineering cybernetics (工程控制论), the workflow now includes a **closed-loop feedback control system** that observes execution reality and automatically corrects course when plans drift:

```
    Set Point (Phase 2 spec)
          │
          ▼
    ┌────────────┐         drift_score + telemetry
    │ Controller │◄────────────────────────────┐
    │ (SKILL)    │                              │
    └─────┬──────┘                              │
          │ task instructions                   │ observe
          ▼                                     │
    ┌────────────┐                              │
    │ Executor   │──── actual effort/SUPER/deps ┘
    │ (Agent)    │
    └─────┬──────┘
          │ code changes
          ▼
    ┌────────────┐
    │ Codebase   │
    └────────────┘
```

After every task, the agent collects **execution telemetry** (actual effort vs. estimated, S.U.P.E.R compliance delta, unplanned dependencies) and updates a cumulative `drift_score`. When drift exceeds percentage-based thresholds:

| Drift Level | Threshold | Automatic Response |
|:------------|:----------|:-------------------|
| Mild | ≥ 20% of phase tasks | Annotate next task with warning |
| Significant | ≥ 40% | Halt and re-decompose remaining tasks |
| Severe | ≥ 60% | Return to Phase 2 for scope re-evaluation |

This ensures the workflow **self-corrects** instead of blindly executing a plan that no longer matches reality.

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

## S.U.P.E.R — The Architectural Backbone

S.U.P.E.R is not a footnote — it is the design philosophy that drives every phase of the workflow and every line of code the agent produces.

> Write code like building with LEGO — each brick has a single job, a standard interface, a clear direction, runs anywhere, and can be swapped at will.

| Principle | Meaning | How It's Enforced |
|:----------|:--------|:------------------|
| **S**ingle Purpose | One module, one job | Analysis phase rates each module's single-responsibility compliance. Tasks that span multiple concerns get decomposed further. |
| **U**nidirectional Flow | Data flows one way | Architecture health check flags circular dependencies. Dependencies must point inward — outer layers depend on inner, never the reverse. |
| **P**orts over Implementation | Contracts before code | Module inventory evaluates whether I/O is schema-defined. Task breakdown requires interface contracts before implementation tasks. |
| **E**nvironment-Agnostic | Runs anywhere | Risk assessment catches hardcoded config and platform-specific assumptions. Config must come from environment variables or config files. |
| **R**eplaceable Parts | Swap without ripple | Each module is rated by replacement cost. If swapping a component causes cascading changes, the architecture is broken. |

### Where S.U.P.E.R Shows Up

S.U.P.E.R isn't just a reference document the agent might read — it's woven into the workflow at every level:

- **Phase 1 — Analysis**: Every module gets a per-principle compliance score (`S🟢 U🟡 P🔴 E🟢 R🟡`). The risk assessment includes a S.U.P.E.R Architecture Health Summary with violation hotspots.
- **Phase 2 — Intent Refinement**: Analysis findings are presented to the user so they can make informed decisions about scope and S.U.P.E.R priorities before task decomposition begins.
- **Phase 3 — Planning**: Each task is annotated with its S.U.P.E.R design drivers (which principles matter most for that task). Early phases prioritize fixing violation hotspots before building new features.
- **Phase 5 — Sub-SKILL**: The full S.U.P.E.R principles are **inlined verbatim** into the generated sub-SKILL (not just referenced), along with a mandatory **10-point code review checklist** that the agent must pass after every task:

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

  **All pass = proceed. 1-2 fail = fix before marking complete. 3+ fail = stop and refactor.**

## Platform Compatibility

The SKILL prompt is written in a generic, platform-neutral way. It gracefully degrades on platforms without certain capabilities — for example, if sub-agents aren't available, it falls back to sequential execution automatically.

**Tested platforms with install scripts:**

- **Claude Code** — installed as a plugin (with enhanced agent/command support)
- **Codex (OpenAI)** — installed as a Codex plugin or directly as a skill
- **Cursor** — installed as a global or project-level skill

**Any other agent** — copy `SKILL.md` (plus the `references/` directory if you want full template and protocol support) to wherever your agent reads instructions. The files have no external dependencies and no platform-specific logic. Works with Windsurf, Cline, Aider, Continue, Roo Code, Augment, or any other coding agent that reads Markdown-based skills or system prompts.

## Installation

### Claude Code

```
/plugin marketplace add zhu1090093659/spec_driven_develop
/plugin install spec-driven-develop@spec-driven-develop
```

After installation, run `/reload-plugins` to activate.

### Codex CLI

This repository includes Codex plugin metadata at `.agents/plugins/marketplace.json` and `plugins/spec-driven-develop/.codex-plugin/plugin.json`.

Install the Codex plugin marketplace from GitHub:

```bash
codex plugin marketplace add zhu1090093659/spec_driven_develop --ref main
```

Then enable `Spec-Driven Develop` from the Codex plugin UI. If your Codex client does not expose the plugin UI yet, add this to `~/.codex/config.toml`:

```toml
[plugins."spec-driven-develop@spec-driven-develop"]
enabled = true
```

Alternative: install only the core skill with the built-in skill installer inside a Codex session:

```text
$skill-installer install https://github.com/zhu1090093659/spec_driven_develop/tree/main/plugins/spec-driven-develop/skills/spec-driven-develop
```

Or install via shell:

```bash
bash <(curl -sL https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main/scripts/install-codex.sh)
```

### Cursor

```bash
bash <(curl -sL https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main/scripts/install-cursor.sh)
```

Or clone the repo and run locally:

```bash
git clone https://github.com/zhu1090093659/spec_driven_develop.git
bash spec_driven_develop/scripts/install-cursor.sh
```

### Other Agents (Generic)

For any other coding agent, grab the SKILL file and place it where your agent reads instructions:

```bash
# Download the SKILL.md
curl -sL https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main/plugins/spec-driven-develop/skills/spec-driven-develop/SKILL.md -o SKILL.md
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

### Manual Trigger (Claude Code)

```
/spec-dev rewrite this Python project in Rust
/dp Our API response times have been spiking recently
```

### Cross-Conversation Continuity

When working on a long-running task across multiple conversations, the agent reads `docs/progress/MASTER.md` at the start of each new session to restore context and continue from where it left off. In GitHub modes, it also queries GitHub for the latest Issue states — PRs may have been merged since the last session.

### Native Task Tracking

When the agent starts a work session, it automatically loads the current phase's pending tasks into the platform's native task tracking tool (e.g. TodoWrite in Claude Code). You get real-time visual progress in your IDE sidebar — no need to open Markdown files manually. In GitHub modes, progress is also visible on the GitHub Milestone and Project board. MASTER.md remains the persistent local index across conversations.

### Progress Export

An optional script exports your progress data to structured JSON, making it easy to import into external project management tools (Linear, Jira, Notion, etc.):

```bash
python scripts/export-progress.py docs/progress/
```

### Archive

When all tasks are marked complete, the agent archives all workflow artifacts (analysis, plan, progress, sub-SKILL) into `docs/archives/<project-name>/` and updates an index at `docs/archives/README.md`. Nothing is deleted — everything is preserved for traceability.

## Project Structure

```
spec_driven_develop/
├── .agents/plugins/marketplace.json          # Codex repo-local plugin marketplace
├── plugins/spec-driven-develop/              # Self-contained Claude Code and Codex plugin
│   ├── .claude-plugin/
│   │   └── plugin.json                       # Claude Code plugin manifest
│   ├── .codex-plugin/
│   │   └── plugin.json                       # Codex plugin manifest
│   ├── skills/
│   │   ├── spec-driven-develop/
│   │   │   ├── SKILL.md                      # Core workflow — works on ANY platform
│   │   │   └── references/
│   │   │       ├── super-philosophy.md       # S.U.P.E.R architecture principles
│   │   │       ├── parallel-protocol.md      # Parallel execution protocol
│   │   │       ├── behavioral-rules.md       # Non-negotiable workflow rules
│   │   │       ├── github-integration.md     # GitHub Issues/Projects/PR protocol
│   │   │       ├── adaptive-control.md      # Closed-loop adaptive control protocol
│   │   │       └── templates/                # Document templates (one per concern)
│   │   │           ├── analysis.md           # Phase 1: with S.U.P.E.R health assessment
│   │   │           ├── plan.md               # Phase 3: with S.U.P.E.R design constraints
│   │   │           ├── progress.md           # Phase 4: cross-conversation tracking
│   │   │           ├── archive.md            # Phase 7: artifact preservation
│   │   │           └── sub-skill.md          # Phase 5: with inlined S.U.P.E.R + checklist
│   │   └── deep-discuss/
│   │       └── SKILL.md                      # Structured deep discussion workflow
│   ├── agents/                               # Claude Code sub-agents (optional)
│   │   ├── project-analyzer.md
│   │   ├── task-architect.md
│   │   └── task-executor.md
│   └── commands/                             # Slash commands (Claude Code)
│       ├── spec-dev.md                       # /spec-dev — launch spec-driven workflow
│       └── dp.md                             # /dp — launch deep discussion
├── scripts/                                  # Installation & utility scripts
│   ├── install-cursor.sh
│   ├── install-codex.sh
│   ├── install-all.sh
│   └── export-progress.py                    # Export progress to JSON
└── LICENSE
```

The essential files for cross-platform use are the `SKILL.md` files and the `references/` directory. Everything else — agents, commands, plugin manifests, and marketplace metadata — is platform-specific enhancement for Claude Code or Codex.

## Star History

<p align="center">
  <a href="https://www.star-history.com/#zhu1090093659/spec_driven_develop&Date" target="_blank">
    <img src="https://api.star-history.com/svg?repos=zhu1090093659/spec_driven_develop&type=Date" alt="Star History" width="600">
  </a>
</p>

## Friendly Links

- [linux.do](https://linux.do)

## License

MIT
