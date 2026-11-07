function messagesFrom(value) {
  if (Array.isArray(value)) return value
  if (Array.isArray(value?.data)) return value.data
  return []
}

function estimateTokens(text) {
  return Math.ceil(text.length / 4)
}

function recordedTokens(message) {
  const tokens = message?.info?.tokens ?? message?.tokens
  if (!tokens) return null
  return (tokens.input ?? 0) + (tokens.output ?? 0) + (tokens.reasoning ?? 0)
    + (tokens.cache?.read ?? 0) + (tokens.cache?.write ?? 0)
}

function partText(part) {
  if (typeof part === "string") return part
  if (!part || typeof part !== "object") return String(part ?? "")
  if (typeof part.text === "string") return part.text
  if (typeof part.content === "string") return part.content
  if (part.state?.content) return partText(part.state.content)
  if (Array.isArray(part.content)) return part.content.map(partText).join("\n")
  return JSON.stringify(part)
}

function messageText(message) {
  const parts = message?.parts ?? message?.content ?? message?.state?.content ?? message?.text ?? []
  if (typeof parts === "string") return parts
  if (!Array.isArray(parts)) return partText(parts)
  return parts.map(partText).join("\n")
}

export default {
  id: "necro.tokenscope",

  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      editor.add({
        name: "tokenscope",
        description: "Estimate token usage for the current OpenCode session by message category.",
        input: {
          type: "object",
          properties: {
            sessionID: { type: "string", description: "Optional session ID." },
            limitMessages: { type: "integer", minimum: 1, maximum: 100 },
          },
          additionalProperties: false,
        },
        async execute(input, toolContext) {
          const sessionID = input?.sessionID ?? toolContext.sessionID
          if (!sessionID) return { content: "TokenScope: no session ID was available." }

          const response = await ctx.session.context({ sessionID })
          const messages = messagesFrom(response).slice(-(input?.limitMessages ?? 10))
          const totals = { system: 0, user: 0, assistant: 0, tool: 0, other: 0 }

          for (const message of messages) {
            const role = message?.info?.role ?? message?.type ?? message?.role ?? "other"
            const category = Object.hasOwn(totals, role) ? role : "other"
            totals[category] += recordedTokens(message) ?? estimateTokens(messageText(message))
          }

          const total = Object.values(totals).reduce((sum, value) => sum + value, 0)
          return {
            content: [
              "## TokenScope",
              "",
              `Estimated tokens: **${total}**`,
              `Messages analyzed: **${messages.length}**`,
              "",
              ...Object.entries(totals).map(([role, value]) => `- ${role}: ${value}`),
              "",
              "Note: uses server token counts when available; otherwise estimates at 1 token per 4 characters.",
            ].join("\n"),
          }
        },
      })
    })
  },
}
