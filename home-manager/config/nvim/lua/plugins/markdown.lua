-- =========================================================
-- Markdown: render-markdown.nvim
-- Oculta asteriscos/numerales y renderiza fórmulas y tablas.
-- Requiere parsers treesitter: markdown, markdown_inline y latex
-- (los garantiza core/treesitter.lua).
-- =========================================================
local ok, render_md = pcall(require, "render-markdown")
if ok then
  render_md.setup({
    -- soporte latex
    latex = { enable = true },

    heading = {
      sign = false,
      icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
      width = "block",
      min_width = 30,
    },
    code = {
      enabled = true,
      render_modes = false,
      sign = true,
      conceal_delimiters = true,
      language = true,
      position = "left",
      language_icon = true,
      language_name = true,
      language_info = true,
      language_pad = 0,
      disable = {},
      disable_background = { "diff" },
      background_inset = 1,
      width = "full",
      left_margin = 0,
      left_pad = 0,
      right_pad = 0,
      min_width = 0,
      border = "hide",
      language_border = "█",
      language_left = "",
      language_right = "",
      above = "▄",
      below = "▀",
      inline = true,
      inline_left = "",
      inline_right = "",
      inline_pad = 0,
      priority = 140,
      highlight = "RenderMarkdownCode",
      highlight_info = "RenderMarkdownCodeInfo",
      highlight_language = nil,
      highlight_border = "RenderMarkdownCodeBorder",
      highlight_fallback = "RenderMarkdownCodeFallback",
      highlight_inline = "RenderMarkdownCodeInline",
      highlight_inline_left = nil,
      highlight_inline_right = nil,
      style = "full",
    },
  })
end
