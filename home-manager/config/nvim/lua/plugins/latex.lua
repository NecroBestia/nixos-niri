-- =========================================================
-- LaTeX: vimtex (compilación, visor, sincronización) + nabla
-- =========================================================
-- vimtex es un plugin Vimscript: no expone módulo Lua. Las opciones
-- vim.g.vimtex_* se leen cuando vimtex inicializa un buffer .tex.
--
-- En Neovim 0.12 vim.pack.add carga los plugin/ (evento Pack), así que
-- vimtex ya está activo aquí; el packadd explícito es un no-op seguro
-- y las opciones siguen siendo leídas por proyecto (por buffer .tex),
-- no al cargar el plugin.
--
-- Zathura: visor minimalista con forward/backward search (synctex).
-- El binario es provisto por el wrapper de Nix.
-- =========================================================
vim.g.vimtex_view_method = "zathura"

-- latexmk: compilador en modo continuo. Recompila al guardar el .tex
-- (el autosave de core/autocmds.lua dispara el ciclo).
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_compiler_latexmk = {
  out_dir = "build", -- PDF y auxiliares en build/ junto al .tex
  aux_dir = "build",
  callback = 1,
  continuous = true, -- recompila al guardar
  executable = "latexmk",
  options = {
    "-pdf",
    "-shell-escape", -- comandos externos desde LaTeX (minted, inkscape)
    "-verbose",
    "-file-line-error", -- errores archivo:línea para <leader>le
    "-synctex=1", -- sincronización código ↔ PDF
    "-interaction=nonstopmode", -- sigue compilando con errores menores
  },
}

-- Conceal: representa comandos LaTeX como símbolos Unicode en el buffer
-- (\alpha → α, \frac{a}{b} → a/b). No modifica el archivo.
vim.g.vimtex_syntax_conceal = {
  default = 1,
  mathzs = 1, -- también dentro de $$...$$ / \(...\)
}

-- packadd vimtex: redundante en 0.12 (vim.pack ya lo cargó) pero
-- inocuo; mantiene el orden opciones-antes-de-activación también
-- compatible con nvim < 0.12.
vim.cmd("packadd vimtex")

-- nabla.nvim: preview inline de ecuaciones en ventana flotante.
-- Sin setup(): se usa con require("nabla").popup() (<leader>me).
-- Requiere el parser treesitter 'latex' (core/treesitter.lua).
local nabla_ok = pcall(require, "nabla")
if not nabla_ok then
  vim.notify("nabla.nvim no está instalado. Ejecuta :PackUpdate para instalarlo.", vim.log.levels.WARN)
end
