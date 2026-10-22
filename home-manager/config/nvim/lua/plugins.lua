-- =========================================================
-- Gestión de plugins con vim.pack (nativo de Neovim 0.11+).
--
-- Este archivo:
--   1. Declara la lista fuente única (vim.pack.add). Los plugins viven
--      en ~/.config/nvim/nvim-pack-lock.json (gestionado en caliente,
--      NO desplegado por home-manager para no volverse read-only).
--   2. Carga la configuración de cada dominio (pscall por archivo:
--      si uno falla, el resto arranca y el error queda notificado).
--
-- La carpeta plugins/ tiene un archivo por dominio:
--   commands, editor, ui, completion, git, latex, focus, markdown, format
-- =========================================================

-- ---------------------------------------------------------
-- Lista fuente (vim.pack.add exige URLs completas: el formato
-- corto "user/repo" NO es válido).
-- ---------------------------------------------------------
local ok_add, add_err = pcall(vim.pack.add, {
    -- Temas visuales
    "https://github.com/folke/tokyonight.nvim",               -- tonos fríos (Tokio de noche)
    "https://github.com/rebelot/kanagawa.nvim",               -- tonos cálidos (arte japonés)
    { src = "https://github.com/bluz71/vim-moonfly-colors", name = "moonfly" }, -- muy oscuro, alto contraste; fallback del init
    "https://github.com/RRethy/base16-nvim",                  -- colorescheme base16, lo usa noctalia.lua

    -- Editor
    { src = "https://github.com/akinsho/toggleterm.nvim", version = "main" }, -- terminal flotante
    { src = "https://github.com/jake-stewart/multicursor.nvim" },             -- cursores tipo VS Code
    "https://github.com/folke/zen-mode.nvim",                 -- modo concentración (ventana centrada)
    "https://github.com/folke/twilight.nvim",                 -- atenúa el código fuera del bloque actual
    "https://github.com/tpope/vim-fugitive",                  -- integración Git (:Git, :G…)

    -- Universidad y matemáticas
    "https://github.com/lervag/vimtex",                       -- motor LaTeX (compilación, visor, sync)
    "https://github.com/jbyuki/nabla.nvim",                   -- preview inline de ecuaciones
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim", version = "main" }, -- markdown renderizado

    -- Ecosistema y análisis de código
    "https://github.com/nvim-mini/mini.nvim",                 -- files/pick/statusline/tabline/etc.
    "https://github.com/rafamadriz/friendly-snippets",        -- snippets (los consume mini.snippets)
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" }, -- parsers/gramáticas
    "https://github.com/neovim/nvim-lspconfig",               -- configs LSP para nvim.lsp nativo
    "https://github.com/stevearc/conform.nvim",               -- formateo con formatters CLI
})
if not ok_add then
  vim.notify("vim.pack.add falló: " .. tostring(add_err), vim.log.levels.ERROR)
end

-- ---------------------------------------------------------
-- Carga de configuraciones (orden: base → dominios).
-- completion va antes de format/git para que core.lsp (que corre
-- luego de este archivo) encuentre a mini.completion ya listo.
-- ---------------------------------------------------------
local plugins = {
  "commands",
  "editor",
  "ui",
  "completion",
  "git",
  "latex",
  "focus",
  "markdown",
  "format",
}
for _, name in ipairs(plugins) do
  local ok, load_err = pcall(require, "plugins." .. name)
  if not ok then
    vim.notify(("plugins.%s falló: %s"):format(name, load_err), vim.log.levels.ERROR)
  end
end
