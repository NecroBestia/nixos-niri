vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format Local buffer" })
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
    "pyright",       -- Python
    "nil_ls",        -- Nix
    "rust_analyzer", -- Rust
    "texlab",        -- Soporte matemático/LaTeX
})