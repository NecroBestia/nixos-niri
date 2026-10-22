-- =========================================================
-- Autocompletado y snippets (mini.completion + mini.snippets)
-- =========================================================

-- ---------------------------------------------------------
-- Autocompletado conectado al LSP (core/lsp.lua entrega las
-- capabilities a los servidores una vez este módulo cargó).
-- ---------------------------------------------------------
local ok_completion, completion = pcall(require, "mini.completion")
if ok_completion then
  completion.setup({ lsp_completion = { auto_setup = true } })
end

-- ---------------------------------------------------------
-- Snippets: friendly-snippets (desde runtimepath vía gen_loader)
-- + snippets matemáticos propios para LaTeX.
-- ---------------------------------------------------------
local snip_ok, MiniSnippets = pcall(require, "mini.snippets")
if not snip_ok then return end

local math_snippets = {
  tex = {
    serie = { body = "\\sum_{n=${1:1}}^{\\infty} ${2:a_n}" },
    intimp = { body = "\\int_{${1:a}}^{\\infty} ${2:f(x)}\\, dx" },
    polar = { body = "x = r \\cos(\\theta) \\\\\ny = r \\sin(\\theta)" },
  },
}

MiniSnippets.setup({
  snippets = {
    MiniSnippets.gen_loader.from_lang(),
    function(context)
      local lang = vim.bo[context.buf_id].filetype
      local snips = math_snippets[lang] or {}
      local res = {}
      for k, v in pairs(snips) do
        table.insert(res, { prefix = k, body = v.body })
      end
      return res
    end,
  },
})
MiniSnippets.start_lsp_server({ match = false })
