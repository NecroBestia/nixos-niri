function messagesFrom(value) {
  if (Array.isArray(value)) return value
  if (Array.isArray(value?.data)) return value.data
  return []
}

function tokenCount(message) {
  const tokens = message?.info?.tokens ?? message?.tokens
  if (!tokens) return null
  return {
    input: tokens.input ?? 0,
    output: tokens.output ?? 0,
    cacheRead: tokens.cache?.read ?? 0,
    cacheWrite: tokens.cache?.write ?? 0,
  }
}

export default {
  id: "necro.deepseek-cache",

  async setup(ctx) {
    const initial = (await ctx.storage.get("stats")) ?? {
      sessions: 0,
      input: 0,
      output: 0,
      cacheRead: 0,
      cacheWrite: 0,
      lastSession: null,
      lastTokens: null,
      baselines: {},
    }

    const baselines = initial.baselines ?? {}

    const update = async (sessionID) => {
      if (!sessionID) return
      const response = await ctx.session.context({ sessionID })
      const messages = messagesFrom(response)
      const assistant = [...messages].reverse().find((message) => tokenCount(message))
      const current = tokenCount(assistant)
      if (!current) return

      const providerID = String(
        assistant?.info?.providerID ?? assistant?.model?.providerID ?? assistant?.providerID ?? "",
      )
      const modelID = String(
        assistant?.info?.modelID ?? assistant?.model?.id ?? assistant?.modelID ?? "",
      )
      if (!/deepseek/i.test(providerID) && !/deepseek/i.test(modelID)) return

      const previous = baselines[sessionID] ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }
      const delta = {
        input: Math.max(0, current.input - previous.input),
        output: Math.max(0, current.output - previous.output),
        cacheRead: Math.max(0, current.cacheRead - previous.cacheRead),
        cacheWrite: Math.max(0, current.cacheWrite - previous.cacheWrite),
      }

      if (initial.lastSession !== sessionID) initial.sessions += 1
      initial.input += delta.input
      initial.output += delta.output
      initial.cacheRead += delta.cacheRead
      initial.cacheWrite += delta.cacheWrite
      initial.lastSession = sessionID
      initial.lastTokens = current
      baselines[sessionID] = current
      initial.baselines = baselines
      await ctx.storage.set("stats", initial)
    }

    const controller = new AbortController()
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ types: ["session.idle"], signal: controller.signal })) {
          await update(event.data?.sessionID ?? event.properties?.sessionID)
        }
      } catch (error) {
        if (!controller.signal.aborted) console.warn("deepseek-cache event loop stopped", error)
      }
    })()

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "cache_stats",
        description: "Show the most recent model token and cache counters recorded by the DeepSeek cache plugin.",
        input: { type: "object", properties: {}, additionalProperties: false },
        async execute() {
          return {
            content: [
              "## DeepSeek cache statistics",
              "",
              `Sessions observed: **${initial.sessions}**`,
              `Input tokens: **${initial.input}**`,
              `Output tokens: **${initial.output}**`,
              `Cache read: **${initial.cacheRead}**`,
              `Cache write: **${initial.cacheWrite}**`,
            ].join("\n"),
          }
        },
      })
    })

    await ctx.command.transform((editor) => {
      editor.add({
        name: "cache-stats",
        description: "Show DeepSeek cache statistics.",
        execute: async ({ sessionID, delivery }) => {
          await ctx.session.synthetic({
            sessionID,
            text: [
              "DeepSeek cache statistics:",
              `sessions=${initial.sessions}`,
              `input=${initial.input}`,
              `output=${initial.output}`,
              `cacheRead=${initial.cacheRead}`,
              `cacheWrite=${initial.cacheWrite}`,
            ].join("\n"),
            delivery,
          })
        },
      })
    })

    return () => controller.abort()
  },
}
