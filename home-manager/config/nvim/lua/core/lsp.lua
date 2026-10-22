-- =========================================================
-- LSPs nativos (vim.lsp.config/enable, Neovim 0.11+) y diagnósticos.
--
-- Los binarios viven SOLO en el PATH del wrapper de Nix
-- (modules/nvim.nix); prolog_ls funciona porque el pack lsp_server
-- está vendado vía XDG_DATA_DIRS del wrapper.
-- El formateo (<leader>f) vive en plugins/format.lua.
-- =========================================================
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "df", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

vim.diagnostic.config({ virtual_text = true })

-- Conecta las capacidades de LSP con el autocompletado de mini.completion.
-- Este archivo se carga tras require("plugins"), así que mini.completion existe.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("mini.completion").get_lsp_capabilities())
vim.lsp.config("*", { capabilities = capabilities })

-- Configs particulares
vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } } } } })
vim.lsp.config("clangd", { cmd = { "clangd", "--background-index" } })

-- Activación de todos los LSPs provistos por el wrapper de Nix
vim.lsp.enable({
    "lua_ls",        -- Lua
    "clangd",        -- C/C++
    "pyright",       -- Python (tipos/diagnósticos)
    "ruff",          -- Python (lint + formateo, LSP nativo 'ruff server')
    "nil_ls",        -- Nix
    "rust_analyzer", -- Rust (formatea vía rustfmt)
    "texlab",        -- LaTeX
    "sqls",          -- SQL
    "prolog_ls",     -- Prolog (pack lsp_server vendado en nvim.nix)
    "hls",           -- Haskell (formatea vía ormolu)
})
