-- =========================================================
-- Formateo: formatter CLI del filetype primero (si existe),
-- si no, LSP con capacidad de formateo, si no, notifica.
-- =========================================================
-- sqlfluff es el formatter real de SQL (sqls anuncia formato pero
-- no implementa uno útil). Dialecto default: postgres — se puede
-- sobreescribir por proyecto con un archivo .sqlfluff.
-- =========================================================
local cli_formatters = {
  sql = { "sqlfluff", "format", "--dialect", "postgres", "-" },
}

local function buf_has_lsp_formatter()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    local caps = client.server_capabilities
    if caps.documentFormattingProvider or caps.documentRangeFormattingProvider then
      return true
    end
  end
  return false
end

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

vim.keymap.set("n", "<leader>f", function()
  local cli = cli_formatters[vim.bo.filetype]
  if cli then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local out = vim.fn.system(cli, lines)
    if vim.v.shell_error ~= 0 then
      vim.notify("Formatter falló: " .. vim.fn.join(vim.split(out, "\n", { trimempty = true }), " "), vim.log.levels.ERROR)
      return
    end
    local new_lines = vim.split(out, "\n")
    if new_lines[#new_lines] == "" then new_lines[#new_lines] = nil end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
    return
  end

  if buf_has_lsp_formatter() then
    vim.lsp.buf.format({ timeout_ms = 5000 })
    return
  end

  vim.notify("Sin formatter para " .. (vim.bo.filetype ~= "" and vim.bo.filetype or "?"), vim.log.levels.INFO)
end, { desc = "Format buffer (CLI por filetype o LSP)" })

vim.keymap.set("n", "df", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

vim.diagnostic.config({ virtual_text = true })

-- Conecta las capacidades de LSP con el autocompletado de mini.completion
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("mini.completion").get_lsp_capabilities())
vim.lsp.config("*", { capabilities = capabilities })

-- Servidores base
vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } } } } })
vim.lsp.config("clangd", { cmd = { "clangd", "--background-index" } })

-- Activación de todos los LSPs provistos por tu wrapper de Nix
vim.lsp.enable({
    "lua_ls",
    "clangd",        -- C/C++
    "pyright",       -- Python (tipos/diagnósticos)
    "ruff",          -- Python (lint + formateo, LSP nativo 'ruff server')
    "nil_ls",        -- Nix
    "rust_analyzer", -- Rust (formatea vía rustfmt)
    "texlab",        -- Soporte matemático/LaTeX
    "sqls",          -- SQL
    "prolog_ls",     -- Prolog (SWI-Prolog: library(lsp_server))
    "hls",           -- Haskell (formatea vía ormolu)
})
