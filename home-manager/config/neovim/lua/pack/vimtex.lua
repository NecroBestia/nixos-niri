-- vimtex: motor LaTeX completo (compilación, vista previa, sincronización).
-- Plugin Vimscript: no expone módulo Lua. Se activa automáticamente al
-- estar en runtimepath (start/ o vía packadd). Las vim.g.vimtex_* se
-- leen en cuanto vimtex se activa (al entrar a un buffer .tex).
--
-- Las opciones deben definirse ANTES del packadd para que vimtex las
-- lea al inicializar el proyecto.
--
-- Zathura: visor minimalista con soporte de forward/backward search.
-- Al hacer gf sobre un \ref{} en el código, Zathura salta a esa posición en el PDF.
vim.g.vimtex_view_method = "zathura"

-- latexmk: compilador estándar que corre en modo continuo.
-- Compila automáticamente al guardar el archivo .tex.
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_compiler_latexmk = {
  out_dir = "build",      -- PDF y auxiliares en build/ junto al .tex
  aux_dir = "build",
  callback = 1,
  continuous = true,        -- Recompila al guardar (evita ejecutar :VimtexCompile manualmente cada vez)
  executable = "latexmk",
  options = {
    "-pdf",
    "-shell-escape",        -- Permite ejecutar comandos externos desde LaTeX (ej. minted, inkscape)
    "-verbose",
    "-file-line-error",     -- Muestra errores con formato archivo:línea para navegar con <leader>le
    "-synctex=1",           -- Sincronización código ↔ PDF (forward/backward search con Zathura)
    "-interaction=nonstopmode", -- No se detiene en errores menores, sigue compilando
  },
}

-- Conceal: reemplaza comandos LaTeX por sus símbolos Unicode en el buffer.
-- \alpha → α, \sum → ∑, \frac{a}{b} → a/b (no modifica el archivo, solo la representación visual).
-- default=1: conceal básico en todo el documento.
-- mathzs=1: conceal en zonas matemáticas ($$...$$, \(...\)) para que se vean más limpias.
vim.g.vimtex_syntax_conceal = {
  default = 1,
  mathzs = 1,
}

-- packadd vimtex: debe ir DESPUÉS de las opciones. Si vimtex ya está en
-- start/ (sources.lua start=true), esto es redundante pero inocuo.
vim.cmd("packadd vimtex")

-- nabla.nvim: previsualización inline de ecuaciones LaTeX en ventana flotante.
-- No tiene setup(), se usa directamente con require("nabla").popup().
-- Requiere el parser treesitter 'latex' instalado (TSInstall latex).
local nabla_ok = pcall(require, "nabla")
if not nabla_ok then
  vim.notify("nabla.nvim no está instalado. Ejecuta :PackUpdate para instalarlo.", vim.log.levels.WARN)
end
