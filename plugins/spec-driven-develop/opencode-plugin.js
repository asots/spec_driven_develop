import { readFile } from "node:fs/promises"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const pluginRoot = dirname(fileURLToPath(import.meta.url))
const skillsPath = join(pluginRoot, "skills")

const stripFrontmatter = (content) =>
  content.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/, "")

const readPrompt = async (relativePath) => {
  const content = await readFile(join(pluginRoot, relativePath), "utf8")
  return stripFrontmatter(content).trim()
}

const unique = (items) => [...new Set(items)]

let assetsPromise

const loadAssets = async () => {
  if (!assetsPromise) {
    assetsPromise = Promise.all([
      readPrompt("commands/spec-dev.md"),
      readPrompt("commands/dp.md"),
      readPrompt("agents/project-analyzer.md"),
      readPrompt("agents/task-architect.md"),
      readPrompt("agents/task-executor.md"),
    ]).then(
      ([specDevCommand, deepDiscussCommand, projectAnalyzer, taskArchitect, taskExecutor]) => ({
        commands: {
          "spec-dev": {
            description: "Launch the Spec-Driven Development workflow for a large-scale project task",
            template: specDevCommand,
          },
          dp: {
            description: "Launch structured deep discussion for problem analysis, solution design, and brainstorming",
            template: deepDiscussCommand,
          },
        },
        agents: {
          "project-analyzer": {
            description:
              "Performs deep codebase analysis for the Spec-Driven Develop workflow. Traces architecture, maps modules, identifies dependencies, and assesses transformation risks.",
            mode: "subagent",
            prompt: projectAnalyzer,
            permission: { edit: "deny" },
          },
          "task-architect": {
            description:
              "Designs phased task decomposition for large-scale project transformations and produces dependency-aware implementation plans.",
            mode: "subagent",
            prompt: taskArchitect,
            permission: { edit: "deny" },
          },
          "task-executor": {
            description:
              "Executes a single development task from the phased plan, including implementation, tests, and structured completion reporting.",
            mode: "subagent",
            prompt: taskExecutor,
          },
        },
      }),
    )
  }

  return assetsPromise
}

export const SpecDrivenDevelopPlugin = async () => {
  const assets = await loadAssets()

  return {
    config: (cfg) => {
      cfg.skills ??= {}
      cfg.skills.paths = unique([...(cfg.skills.paths ?? []), skillsPath])

      cfg.command ??= {}
      for (const [name, command] of Object.entries(assets.commands)) {
        if (!cfg.command[name]) {
          cfg.command[name] = command
        }
      }

      cfg.agent ??= {}
      for (const [name, agent] of Object.entries(assets.agents)) {
        if (!cfg.agent[name]) {
          cfg.agent[name] = agent
        }
      }
    },
  }
}

export default SpecDrivenDevelopPlugin
