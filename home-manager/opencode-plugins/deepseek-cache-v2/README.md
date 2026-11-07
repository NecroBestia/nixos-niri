# DeepSeek cache V2

Native OpenCode V2 replacement for the old V1 DeepSeek cache plugin. It keeps
DeepSeek-only token/cache deltas in plugin storage, with a baseline per session,
and exposes `cache_stats` plus `/cache-stats`. It does not alter provider
requests or system prompts.
