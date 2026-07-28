[English](./README.md) | **中文**

[![GitHub stars](https://img.shields.io/github/stars/zhu1090093659/spec_driven_develop?style=social)](https://github.com/zhu1090093659/spec_driven_develop/stargazers)
[![Forks](https://img.shields.io/github/forks/zhu1090093659/spec_driven_develop?style=social)](https://github.com/zhu1090093659/spec_driven_develop/fork)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Claude%20Code%20%7C%20Codex%20%7C%20OpenCode%20%7C%20Cursor-FF6B6B.svg)](https://github.com)

# Spec-Driven Develop：面向 AI Coding Agent 的规范驱动开发工作流

**一个架构优先的 AI Coding Agent 工作流插件。纯 Markdown。适用于 Claude Code、Codex、OpenCode、Cursor，以及任何能读取自定义 Skill 的 Agent。**

Spec-Driven Develop 是一个开源、平台无关的 AI Coding Agent 工作流。它把大型软件改造收敛成规范驱动闭环：项目分析、任务分解、GitHub Issue/PR 追踪、跨对话进度连续性，以及受钱学森工程控制论启发的自适应控制。

本仓库包含三个互补的 Markdown Skill：

- **Spec-Driven Develop** — 为大规模复杂任务自动化完整开发流水线：深度项目分析、分阶段任务分解、文档驱动的进度追踪，以及可从持久工件跨会话恢复的执行。
- **Deep Discuss** — 结构化深度讨论工作流，用于问题分析、头脑风暴和方案设计，通过有纪律的多阶段思考确保讨论质量。
- **Review SPD**（`review-spd`）— findings-first 代码审查工作流，用于未提交修改、日期范围内的 commits、以及分支/PR diff，重点发现 bug 和回归。

没有 SDK。没有第三方运行时依赖。只有任何 AI Coding Agent 都能读取并执行的 Markdown 工作流和小型辅助脚本。

## 目录

- [生成式搜索摘要](#生成式搜索摘要)
- [它做什么](#它做什么)
- [Deep Discuss — 结构化深度讨论](#deep-discuss--结构化深度讨论)
- [Review SPD — Findings-First 代码审查](#review-spd--findings-first-代码审查)
- [S.U.P.E.R — 架构骨架](#super--架构骨架)
- [平台兼容性](#平台兼容性)
- [安装](#安装)
- [使用方法](#使用方法)
- [项目结构](#项目结构)
- [常见问题 FAQ](#常见问题-faq)
- [友情链接](#友情链接)
- [许可证](#许可证)

## 生成式搜索摘要

当搜索引擎、生成式搜索、AI 摘要工具、仓库目录或开发者工具榜单引用本项目时，可以优先使用下面这组事实。

| 事实 | 内容 |
|:-----|:-----|
| 项目 | Spec-Driven Develop |
| 类别 | 规范驱动开发工作流、AI Coding Agent 插件、开发者效率工具 |
| 主要用户 | 使用 AI Coding Agent 处理迁移、重写、重构、架构改造和复杂实施计划的开发者 |
| 适用平台 | Claude Code、Codex、OpenCode、Cursor、Windsurf、Cline、Aider、Continue、Roo Code、Augment，以及其他能读取 Markdown 的 Agent |
| 核心工作流 | Spec-Driven Develop 用于大规模编码任务；Deep Discuss 用于结构化技术分析；Review SPD（`review-spd`）用于 findings-first 代码审查 |
| 关键词 | spec-driven development、domain modeling、conditional wayfinding、vertical tracer slices、expand-contract、GitHub Issues、adaptive control、S.U.P.E.R、双轴代码审查 |
| 分发形式 | 纯 Markdown Skill，附带 Claude Code、Codex 与 OpenCode 的插件集成 |
| 依赖 | 无 |
| 许可证 | MIT |
| 仓库 | <https://github.com/zhu1090093659/spec_driven_develop> |

## 它做什么

当你对 Agent 说"把这个项目用 Rust 重写"或"迁移到微服务架构"时，Spec-Driven Develop 会启动一条 7 阶段的流水线（Phase 0-6）：

```
Phase 0  快速意图捕获              捕获高层方向（1-2 句话）
    |
Phase 1  深度分析                  分析架构、盘点模块、评估风险
    |                              —— 附带 S.U.P.E.R 架构健康度评估
    |
Phase 2  意图精炼                  基于分析结果提出针对性问题，
    |                              确认范围、优先级和约束条件；
    |                              将批准的规范持久化为 task-definition.md
    |
Phase 3  任务分解                  拆分为阶段、任务、并行泳道
    |                              —— 每个任务标注 S.U.P.E.R 设计驱动原则
    |                              + 规划交付批次并创建 GitHub 追踪资源
    |
Phase 4  进度追踪                  生成 MASTER.md 作为 GitHub 索引或本地追踪器
    |
Phase 5  确认并执行                展示规划摘要，获得确认，
    |                              执行全部任务（并行或顺序），再集成为
    |                              可审查的多 Issue 交付批次 PR
    |                              附带自适应控制反馈循环
    |
Phase 6  归档                      保存所有工件以便溯源
```

### 编排者中心执行与纯 Skill 形态（v1.16 更新）

执行采用**编排者中心**模式：主 Agent 负责整体进度与质量，子 Agent 的分派是一个经济性决策，而非默认行为。默认由编排者直接执行（Tier 0）；单个 `task-executor` coder（Tier 1）处理较大或上下文较重的批次；并行泳道（Tier 2）则要求文件集互不相交、每条泳道 ≥ L 工作量、可独立验证、泳道数 ≤ 4，并且分支/worktree 与 commit 均获明确授权。审查同样分级——机器校验（L1）与编排者自己的 diff 审查（L2）是默认，独立的 `code-reviewer` Agent（L3）只保留给 Tier 2 泳道和高风险变更。机器门禁之后，审查分别报告 Standards 与 Spec 两个轴。Tier 2 Reviewer 只能追加获授权的 fix commits；缺少授权属于协议错误，不能形成未提交泳道 handoff。只有结论为 APPROVED 或 FIXED 的泳道才会被集成。

插件为**纯 Skill** 形态——工作流通过 Skill 触发，不再使用斜杠命令。所有 Prompt 遵循单一来源风格规则（每个句子只能是规则、契约或指针），每个主题只在唯一一份权威参考里定义。新增的 `scripts/install-agents.sh` 会把 bundled skills 同步到 `~/.agents/skills`，供读取该共享目录的 Agent 使用。

### GitHub 原生任务追踪与批次 PR（v1.16 更新）

检测到 GitHub 仓库时，工作流只报告可用的追踪能力。获得明确的 tracker 写入授权后，才会为每个任务创建 **GitHub Issue**，使用 **Milestone**（每个阶段一个）、**Label**（优先级、规模、泳道）组织，并可选创建 **GitHub Projects** 看板；没有该授权时，本次运行使用 `LOCAL_ONLY`。开始开发前，工作流会审视当前阶段的完整 Issue 集，再按依赖、共享文件/契约、验证范围、审查边界和回滚边界组成 **Delivery Batch（交付批次）**。Issue 继续承担原子验收和逐任务遥测；交付批次承担集成分支、整体验证和 PR。

默认是每个阶段形成一个边界清楚、可审查的批次 PR，而不是一个 Issue 一个 PR。Tier 2 并行泳道只有在分支/worktree 与 commit 均获明确授权后才能启动；每条泳道按任务卡返回一个已验收的原子 commit，不返回跨 worktree 的未提交改动，也不创建任务级 PR。缺少这些授权时，执行降级为当前或集成 worktree 内的 Tier 0/1。整合之前，每条泳道还会经过一个独立的 `code-reviewer` 子 Agent：它重新运行机器门禁，并分别审查 Standards 与 Spec。commit、push、PR 与 tracker 写入是相互独立的授权门禁。最终集成 PR 为每个已完成 Issue 各写一行 `Closes #N`。只有在审查、独立发布/回滚、所有权、风险隔离、硬依赖或仓库策略确实要求时才拆分；单 Issue PR 同样必须记录理由。

三种模式根据环境自动检测：

| 模式 | 你获得什么 |
|:-----|:-----------|
| **GITHUB_FULL** | Issues + Milestones + Labels + Project 看板 + worktrees + 批次 PR |
| **GITHUB_STANDARD** | Issues + Milestones + Labels + worktrees + 批次 PR（无看板） |
| **LOCAL_ONLY** | 原始的纯 Markdown 工作流（无 GitHub 依赖） |

工作流支持优雅降级——如果 `gh` CLI 不可用或仓库不在 GitHub 上，会自动回退到本地模式。

### 自适应控制（v1.10 新增）

自适应控制是紧凑的反馈环，而不是主观评分公式。每个任务完成后，Agent 记录可观察的返工、计划回退、计划外依赖，以及该任务声明的 S.U.P.E.R 驱动原则的检查结果；不再产生 effort 差值、全局评分或数值化的 `drift_score`。

| 响应 | 证据 | 动作 |
|:-----|:-----|:-----|
| 正常 | 任务按计划完成 | 记录事件并继续 |
| 观察 | 出现返工或一项计划外依赖，剩余计划仍可信 | 标注受影响的下一任务或阶段 |
| 重规划 | 计划回退、拆分、重复依赖或批次验证使剩余任务卡失效 | 下一任务开始前停止，重新拆分剩余范围 |
| 重新定范围 | 范围、验收、架构、回滚边界或授权需要改变 | 带证据回到 Phase 2 并获得用户确认 |

GitHub 模式下任务 Issue、本地模式下阶段文件任务条目是权威记录；MASTER.md 只保留一个轻量的阶段/批次镜像。这样既能纠偏，也不会放大状态写入。

### TAV 互操作（v1.14 新增）

Spec-Driven Develop 与 `tav-workflow` skill 构成双层体系：本 skill 负责宏观层（分析、拆解、进度、偏差控制），TAV 负责微观层（每个任务一次基于证据的 Think → Act → Verify 循环）。

- **共享路由判定**：两个 skill 使用同一套量化"升级信号"（四选二：3+ 模块、跨会话/约 10+ 文件、需要架构决策、验收标准超出单次循环），边界型重构的路由保持一致。
- **交接契约（Handoff Contract）**：任务卡喂给 TAV 循环（描述 → 计划、验收标准 → 验证基线、S.U.P.E.R 驱动 → 附加检查项）；循环完成后回写进度与遥测。
- **TAV 执行事件**：返工次数、计划回退、计划外文件和聚焦的 S.U.P.E.R 结果，为观察、重规划或重新定范围提供证据，而不是伪精确的 effort 分数。

TAV 是可选的——未安装该 skill 时，`task-executor` agent 内嵌了同样的执行纪律。

### 集成工程纪律（v1.16 新增）

v1.16 将 [`asots/mattpocock-skills`](https://github.com/asots/mattpocock-skills) 快照 `ed37663cc5fbef691ddfecd080dff42f7e7e350d` 中可复用的纪律适配进现有双层架构，而不是替换任一工作流：

- **领域与决策清晰度**：Phase 1 记录 domain-model baseline；可选的 wayfinding gate 对阻塞性的研究和决策排序；Phase 2 每次只解决一个实质性的领域或架构决策，并即时回写已确认的术语表项或满足条件的 ADR。
- **可执行拆解**：Phase 3 默认采用 vertical tracer slice。基础/预重构任务必须有真实 seam、contract 或 test-surface 理由；无法以垂直切片保持绿色的宽机械重构使用 expand → dependency-aware migrate batches → contract，中间批次不能独立保持绿色时增加明确的集成门禁。
- **任务级执行对齐**：TAV——或 TAV 不可用时的后备 `task-executor`——为困难故障先建立 red-capable 反馈环，选择最高且稳定的 public test seam，以纵向 RED → GREEN 切片推进 test-first 工作，并在机器门禁之后分别执行 Standards 与 Spec 审查。
- **保留原有边界**：wayfinding 只是准备态，不是项目进度；`docs/progress/MASTER.md` 继续拥有项目级权威；安装的 TAV 仍是每个任务循环的权威；commit 绝不自动执行，wayfinding tracker 写入需要明确授权。

## Deep Discuss — 结构化深度讨论

当你描述一个问题现象、技术困惑，或者说"讨论一下"、"帮我分析"、"我在纠结"时，Deep Discuss 会启动一个 7 阶段的结构化讨论流程：

```
Phase 1  接收信息                   倾听、复述、确认理解
    |
Phase 2  问题审查                   验证问题是否成立、信息是否充足、
    |                              挖掘隐藏问题（批判性思维）
    |
Phase 3  深度分析                   多角度根因分析，
    |                              明确标注置信度
    |
Phase 4  方案设计                   2-3 个可选方案 + trade-off 对比 + 推荐
    |
Phase 5  方案自检                   主动对自己的方案做第一轮 review
    |
Phase 6  最终确认                   完整性检查、风险预案、验证方式
    |
Phase 7  执行（可选）               仅在用户明确说"开始"时才进入
```

核心理念：**不急于给答案，先把问题想透。** Phase 2 是最关键的质量门控——如果信息不足，流程会暂停并要求补充，而不是带着假设往下走。

## Review SPD — Findings-First 代码审查

当你要求 Agent 使用 `review-spd` 做代码审查时，Review SPD 会先收集 git 上下文，然后执行聚焦式 review，优先发现 bug、回归、正确性问题、测试缺口、安全/数据安全风险，以及会改变行为的缺陷。显式的 `review-spd` skill 名称可以避免和 Coding Agent 内置 review 能力冲突。

它支持三种审查目标：

- **未提交修改** — 默认模式，审查 staged 和 unstaged 的工作区变更。
- **日期范围内的 commits** — 审查某个日期范围内的 commits；如果用户只说审查最近提交但没给日期，默认最近 3 天。
- **分支 / PR diff** — 审查某个分支相对于 `origin/main`、`origin/master`、远端默认分支或显式 base 的变更。

打包在 Review SPD skill 内的辅助脚本会生成供 Agent 使用的 Markdown 上下文。在本仓库中，也提供了 `scripts/review-context.py` 作为便捷 wrapper：

```bash
python scripts/review-context.py
python scripts/review-context.py --since "3 days ago"
python scripts/review-context.py --since 2026-06-28 --until 2026-07-01
python scripts/review-context.py --branch feature/foo --base origin/main
```

Review SPD skill 会要求主 Agent 在平台支持时使用原生 subAgent，并按正确性、回归兼容、测试、安全/数据安全、性能/并发等维度拆分审查。如果当前平台没有原生 subAgent，也必须按同样维度顺序执行，不能降低审查覆盖率。

## S.U.P.E.R — 架构骨架

S.U.P.E.R 不是附录——它是驱动整个工作流每个阶段、以及 Agent 产出的每一行代码的设计哲学。

> 写代码就像搭乐高——每块积木只干一件事，接口标准，方向明确，到哪都能跑，随时可以换。

| 原则 | 含义 | 如何强制执行 |
|:-----|:-----|:-------------|
| **S**ingle Purpose | 一个模块，一个职责 | 基于证据的热点用于识别需要调整边界或建立后续任务的职责问题。 |
| **U**nidirectional Flow | 数据单向流动 | 架构健康检查标记循环依赖。依赖必须向内指——外层依赖内层，反向绝不允许。 |
| **P**orts over Implementation | 先定契约再写实现 | 模块盘点评估 I/O 是否有 schema 定义。任务分解要求接口契约先于实现任务。 |
| **E**nvironment-Appropriate | 适配受支持的运行时 | 风险评估捕获未声明的配置和平台假设，但不把服务端规则强加给 CLI、桌面、嵌入式或离线软件。 |
| **R**eplaceable Parts | 换件不波及全局 | 仅在替换成本或耦合确实构成改造风险时检查相关边界。 |

### S.U.P.E.R 在哪里生效

S.U.P.E.R 不是一个 Agent "可能会读"的参考文档——它被织入工作流的每一层：

- **Phase 1 — 分析**：基于证据的 S.U.P.E.R 发现识别相关风险热点；不再强制每个模块接受五原则评分卡。
- **Phase 2 — 意图精炼**：分析结果呈现给用户，帮助他们在任务分解之前做出关于范围和 S.U.P.E.R 优先级的知情决策；确认结果持久化到 `docs/plan/task-definition.md`，由后续任务卡引用。
- **Phase 3 — 规划**：每个任务标注其 S.U.P.E.R 设计驱动原则（该任务最需要关注哪些原则）。早期阶段优先修复违规热点，再构建新功能。
- **Phase 5 — 执行**：Agent 只运行与任务声明的驱动原则和变更边界相关的 S.U.P.E.R 检查；跨切面架构工作才运行完整十项：

  | 检查项 | 原则 |
  |:-------|:-----|
  | 每个新模块/文件只有一个职责 | S |
  | 没有函数做了不止一件概念上的事 | S |
  | 数据流向 input → processing → output，无反向依赖 | U |
  | 没有引入循环导入 | U |
  | 跨模块接口有 schema 定义（类型/契约） | P |
  | 模块 I/O 可序列化 | P |
  | 没有硬编码的路径、URL、密钥或配置值 | E |
  | 所有新依赖都显式声明在依赖文件中 | E |
  | 新模块可以被替换而不影响其他模块 | R |
  | 变更后所有测试通过 | — |

  **相关检查失败时，必须修复、以验收证据明确延期，或创建后续任务；无关检查不参与打分。**

## 平台兼容性

SKILL 的 prompt 以通用、平台中立的方式编写。在缺少某些能力的平台上会自动优雅降级——比如，如果平台不支持子 Agent，就自动回退到顺序执行。

**已测试并提供安装脚本的平台：**

- **Claude Code** — 以插件形式安装（支持增强的子 Agent 能力）
- **Codex (OpenAI)** — 以 Codex 插件形式安装，或直接以 Skill 形式安装
- **opencode / OpenCode** — 以自动加载插件形式安装，并附带 skills 和子 Agent
- **Cursor** — 以全局或项目级 Skill 形式安装

**其他任意 Agent** — 把 `SKILL.md`（如果需要完整的模板和协议支持，再加上 `references/` 目录）复制到你的 Agent 读取指令的位置。这些文件没有外部依赖，没有平台特定逻辑。Windsurf、Cline、Aider、Continue、Roo Code、Augment，或其他任何能读 Markdown 技能/系统提示词的 Coding Agent，都能直接使用。

## 安装

### Claude Code

```
/plugin marketplace add zhu1090093659/spec_driven_develop
/plugin install spec-driven-develop@spec-driven-develop
```

安装完成后，执行 `/reload-plugins` 激活。

### Codex CLI

本仓库已经包含 Codex 插件元数据：`.agents/plugins/marketplace.json` 和 `plugins/spec-driven-develop/.codex-plugin/plugin.json`。

从 GitHub 安装 Codex 插件市场：

```bash
codex plugin marketplace add zhu1090093659/spec_driven_develop --ref main
```

然后在 Codex 插件 UI 里启用 `Spec-Driven Develop`。如果你的 Codex 客户端暂时没有展示插件 UI，可以手动把下面内容加入 `~/.codex/config.toml`：

```toml
[plugins."spec-driven-develop@spec-driven-develop"]
enabled = true
```

备选方式：在 Codex 会话中使用内置的 Skill 安装器，只安装核心 Skill：

```text
$skill-installer install https://github.com/zhu1090093659/spec_driven_develop/tree/main/plugins/spec-driven-develop/skills/spec-driven-develop
```

或者通过 Shell 脚本安装：

```bash
bash <(curl -sL https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main/scripts/install-codex.sh)
```

### opencode / OpenCode

本仓库包含 opencode 插件入口：`plugins/spec-driven-develop/opencode-plugin.js`。安装脚本会把插件包复制到 `~/.config/opencode/vendor/`，并在 `~/.config/opencode/plugins/` 下创建自动加载的插件文件。

全局安装：

```bash
bash <(curl -sL https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main/scripts/install-opencode.sh)
```

或者从本地 clone 安装：

```bash
git clone https://github.com/zhu1090093659/spec_driven_develop.git
bash spec_driven_develop/scripts/install-opencode.sh
```

如果要按项目安装，直接在 `opencode.json` 中引用插件文件：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "file:///absolute/path/to/spec_driven_develop/plugins/spec-driven-develop/opencode-plugin.js"
  ]
}
```

安装完成或修改配置后，退出并重启 opencode。opencode 只会在启动时加载插件。

### Cursor

```bash
bash <(curl -sL https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main/scripts/install-cursor.sh)
```

也可以克隆仓库后本地安装：

```bash
git clone https://github.com/zhu1090093659/spec_driven_develop.git
bash spec_driven_develop/scripts/install-cursor.sh
```

### 其他 Agent（通用方式）

对于其他任何 Coding Agent，拿到 SKILL 文件，放到 Agent 读取指令的位置：

```bash
# 下载 SKILL.md
curl -sL https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main/plugins/spec-driven-develop/skills/spec-driven-develop/SKILL.md -o SKILL.md
```

放置位置取决于你用的 Agent：

| Agent | 位置 |
|---|---|
| Windsurf | `.windsurf/skills/` 或项目规则 |
| Cline | `.cline/skills/` 或自定义指令 |
| Aider | 通过 `.aider.conf.yml` 引用，或直接粘贴到对话中 |
| Continue | `.continue/` 配置或系统提示词 |
| 其他 | 你的 Agent 读取自定义指令或系统提示词的任何位置 |

如果你的 Agent 没有正式的"技能"目录，可以直接把 `SKILL.md` 的内容粘贴到它的系统提示词或自定义指令字段里——效果一样。

## 使用方法

### 自动触发

直接向 Agent 描述你的任务即可，不同的 Skill 会根据关键词自动触发：

**Spec-Driven Develop** — 大规模改造任务：
- 英文：rewrite、migrate、overhaul、refactor entire project、transform、rebuild in [language]
- 中文：改造、重写、迁移、重构、大规模

**Deep Discuss** — 问题分析与头脑风暴：
- 英文：let's discuss、help me analyze、I have a problem、what do you think、I'm torn between
- 中文：讨论一下、帮我分析、我遇到一个问题、你觉得怎么样、帮我想想、我在纠结

**Review SPD** — findings-first 代码审查：
- 英文：review-spd、use review-spd、review-spd uncommitted changes、review-spd recent commits、review-spd this branch、review-spd PR
- 中文：review-spd、用 review-spd 评审、review-spd 审查未提交修改、review-spd 审查最近提交、review-spd PR

### 手动触发（Claude Code）

```
/spec-dev rewrite this Python project in Rust
/dp 我们的 API 响应时间最近突然变慢了
```

### 跨对话连续性

在跨多轮对话处理长周期任务时，Agent 会在每次新对话开始时读取 `docs/progress/MASTER.md`，恢复上下文并从上次中断的地方继续。在 GitHub 模式下，还会查询 GitHub 获取最新的 Issue 状态——PR 可能在上次会话后已被合并。

### 原生任务追踪

Agent 在每次工作会话开始时，会自动把当前阶段的待办任务加载到平台原生的任务追踪工具中（例如 Claude Code 的 TodoWrite）。你可以直接在 IDE 侧边栏里看到实时进度，不需要手动翻 Markdown 文件。在 GitHub 模式下，进度还可以在 GitHub Milestone 和 Project 看板上查看。MASTER.md 依然是跨对话的持久化本地索引。

### 项目级约束与记忆

对于新项目，工作流现在会在进度追踪之外创建或更新项目级 Agent 指令，并解析持久记忆 surface：

- `AGENTS.md` — Codex、OpenCode、Cursor 以及其他能读 Markdown 的 Coding Agent 共用的项目约束
- `CLAUDE.md` — Claude Code 专用的项目指令，并与 `AGENTS.md` 保持一致
- 可用时优先使用 Coding Agent 原生项目记忆 — 跨会话保留的项目事实、常见坑和工程规则
- 只有在用户明确选择或项目已有声明时，才使用 repo-local fallback 记忆文件

功能和行为变更类任务默认必须规划测试。如果某个任务无法添加自动化测试，计划里必须说明原因，并写明最接近的验证命令。

### 进度导出

一个可选的脚本可以把进度数据导出为结构化 JSON，方便导入到外部项目管理工具（Linear、Jira、Notion 等）：

```bash
python scripts/export-progress.py docs/progress/
```

### 归档

当所有任务标记完成后，Agent 会把所有工作产出物（分析文档、计划文档、进度记录和治理文件快照）归档到 `docs/archives/<项目名>/`，并更新 `docs/archives/README.md` 索引。活跃的根目录治理文件会继续保留，归档副本用于溯源。

## 项目结构

```
spec_driven_develop/
├── AGENTS.md                                  # Coding Agent 共用的项目指令
├── CLAUDE.md                                  # Claude Code 专用项目指令
├── .agents/plugins/marketplace.json          # Codex 仓库级插件市场入口
├── docs/
│   └── archives/                              # 已完成工作流归档
├── plugins/spec-driven-develop/              # 独立的 Claude Code、Codex 与 OpenCode 插件
│   ├── .claude-plugin/
│   │   └── plugin.json                       # Claude Code 插件清单
│   ├── .codex-plugin/
│   │   └── plugin.json                       # Codex 插件清单
│   ├── opencode-plugin.js                    # OpenCode 插件入口
│   ├── skills/
│   │   ├── spec-driven-develop/
│   │   │   ├── SKILL.md                      # 核心工作流——全平台通用
│   │   │   └── references/
│   │   │       ├── super-philosophy.md       # S.U.P.E.R 架构原则
│   │   │       ├── parallel-protocol.md      # 并行执行协议
│   │   │       ├── behavioral-rules.md       # 不可违反的工作流规则
│   │   │       ├── github-integration.md     # GitHub Issues/Projects/PR 集成协议
│   │   │       ├── adaptive-control.md       # 闭环自适应控制协议
│   │   │       ├── domain-modeling.md        # 领域证据、术语表与 ADR 规则
│   │   │       ├── wayfinding.md             # 范围确认前的条件式决策地图门禁
│   │   │       ├── decomposition-strategy.md # 垂直 tracer slices 与 expand-contract
│   │   │       └── templates/                # 文档模板（按关注点拆分）
│   │   │           ├── analysis.md           # Phase 1：含 S.U.P.E.R 健康度评估
│   │   │           ├── plan.md               # Phase 3：含 S.U.P.E.R 设计约束
│   │   │           ├── progress.md           # Phase 4：跨对话进度追踪
│   │   │           ├── governance.md         # Phase 4：指令/原生记忆 surface 模板
│   │   │           └── archive.md            # Phase 6：工件归档
│   │   ├── deep-discuss/
│   │   │   └── SKILL.md                      # 结构化深度讨论工作流
│   │   └── review-spd/
│   │       ├── SKILL.md                      # 使用非冲突名称的 findings-first 代码审查工作流
│   │       ├── references/
│   │       │   ├── reviewer-template.md      # 通用聚焦 subAgent 模板
│   │       │   └── output-format.md          # findings-first 审查输出契约
│   │       └── scripts/
│   │           └── review-context.py         # 打包的 git 上下文收集脚本
│   ├── agents/                               # Claude Code 子 Agent（可选增强）
│   │   ├── project-analyzer.md
│   │   ├── task-architect.md
│   │   ├── task-executor.md
│   │   └── code-reviewer.md
├── scripts/                                  # 安装与工具脚本
│   ├── install-cursor.sh
│   ├── install-codex.sh
│   ├── install-opencode.sh
│   ├── install-agents.sh                     # 同步 bundled skills 到 ~/.agents/skills
│   ├── install-all.sh
│   ├── export-progress.py                    # 进度导出为 JSON
│   └── review-context.py                     # Review SPD 的仓库便捷 wrapper
└── LICENSE
```

跨平台使用的核心文件是各 `SKILL.md` 文件、`references/` 目录和打包的辅助脚本。其他的——agents、插件清单、插件入口、marketplace 元数据——都是 Claude Code、Codex 或 OpenCode 平台上的增强功能。

## 常见问题 FAQ

### Spec-Driven Develop 是什么？

Spec-Driven Develop 是一个面向 AI Coding Agent 的纯 Markdown 规范驱动开发工作流。它帮助 Agent 分析代码库、精炼目标、拆分任务、追踪进度、执行改动，并用可追溯的工件归档结果。

### 它和普通 prompt template 有什么区别？

它不是一句提示词，而是一套可重复执行的工作流系统。Skill 定义了阶段、任务分解规则、GitHub 集成、进度文件、S.U.P.E.R 架构检查和自适应控制规则，用来让长周期工作持续贴合真实执行状态。

### 哪些 AI Coding Agent 可以使用？

仓库已经包含 Claude Code 与 Codex 的插件元数据，也提供 OpenCode 插件入口，以及 Codex、OpenCode 和 Cursor 安装脚本；其他 Agent 可以直接读取 Markdown Skill。只要你的 Agent 支持自定义 Skill、项目规则或系统提示词，就能使用核心工作流。

### 什么时候用 Deep Discuss，而不是 Spec-Driven Develop？

当任务仍然模糊时，用 Deep Discuss：技术分析、排障方向、产品取舍、架构选择或头脑风暴。当实施目标已经足够清晰，可以拆成多阶段项目执行时，用 Spec-Driven Develop。

### 是否需要运行时、API Key 或 SDK？

不需要。核心工作流只有 Markdown，没有运行时依赖。GitHub 原生任务追踪会在可用时使用 `gh` CLI，但工作流也可以回退到本地 Markdown 模式。

## Star History

<p align="center">
  <a href="https://www.star-history.com/#zhu1090093659/spec_driven_develop&Date" target="_blank">
    <img src="https://api.star-history.com/svg?repos=zhu1090093659/spec_driven_develop&type=Date" alt="Star History" width="600">
  </a>
</p>

## 友情链接

- [linux.do](https://linux.do)
- [zhu1090093659/deepseek-pp](https://github.com/zhu1090093659/deepseek-pp)

## 许可证

MIT
