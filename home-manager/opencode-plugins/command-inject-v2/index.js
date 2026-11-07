import { readFile } from "node:fs/promises"
import path from "node:path"

const commandName = (name) => name.replace(/[^a-zA-Z0-9_-]/g, "-").replace(/^-+|-+$/g, "")

async function discoverCommands(root) {
  const commands = []

  try {
    const makefile = await readFile(path.join(root, "Makefile"), "utf8")
    for (const line of makefile.split("\n")) {
      const match = line.match(/^([A-Za-z0-9_.-]+):(?:[^=]|$)/)
      if (match && !match[1].startsWith(".")) {
        commands.push({
          name: commandName(`make-${match[1]}`),
          description: `Run Make target ${match[1]}`,
          command: `make ${match[1]}`,
        })
      }
    }
  } catch {}

  try {
    const packageJson = JSON.parse(await readFile(path.join(root, "package.json"), "utf8"))
    const runner = typeof packageJson.packageManager === "string"
      ? packageJson.packageManager.split("@")[0]
      : "npm"
    for (const [name, script] of Object.entries(packageJson.scripts ?? {})) {
      commands.push({
        name: commandName(`${runner}-${name}`),
        description: `Run package script ${name}`,
        command: `${runner} run ${name} --`,
        script,
      })
    }
  } catch {}

  return [...new Map(commands.map((command) => [command.name, command])).values()]
}

export default {
  id: "necro.command-inject",

  async setup(ctx) {
    const commands = await discoverCommands(ctx.location.directory)
    if (commands.length === 0) return

    await ctx.command.transform((editor) => {
      for (const command of commands) {
        editor.add({
          name: command.name,
          description: command.description,
          execute: async ({ sessionID, prompt, delivery }) => {
            const argumentsText = prompt?.text?.trim()
            const shellCommand = argumentsText ? `${command.command} ${argumentsText}` : command.command
            const text = `Use shell to execute \`${shellCommand}\``
            await ctx.session.prompt({ sessionID, text, delivery })
          },
        })
      }
    })
  },
}
