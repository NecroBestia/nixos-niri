-- =========================================================
-- Punto de entrada de la configuración.
--
-- Orden de carga (el orden importa):
--   1. core.options/autocmds/keymaps: base sin plugins.
--   2. plugins: vim.pack.add (clona) + setup de cada uno.
--   3. core.treesitter / core.lsp: dependen de plugins ya cargados
--      (treesitter de nvim-treesitter; lsp de mini.completion).
--   4. Tema visual: noctalia.lua se genera en caliente por la plantilla
--      de Noctalia (config/noctalia/templates/nvim-base16.lua) con los
--      colores del wallpaper; fallback a moonfly.
-- =========================================================

-- Definir teclas líder ANTES de cargar los plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI experimental de Neovim 0.12. En pcall: si la API interna desaparece
-- en otra versión, la config arranca igual (sin la UI nueva).
pcall(function() require("vim._core.ui2").enable({}) end)

-- 1. Configuración base que no necesita plugins
require("core.options")
require("core.autocmds")
require("core.keymaps")

-- 2. Plugins (gestor nativo vim.pack + setups)
require("plugins")

-- 3. Módulos que dependen de plugins ya cargados
require("core.treesitter")
require("core.lsp")

-- 4. El tema visual
local ok = pcall(require, "noctalia")
if ok then
  require("noctalia").setup()
else
  vim.cmd.colorscheme("moonfly")
end
