local opt = vim.opt

-- Desactiva el banner molesto del explorador de archivos nativo
vim.g.netrw_banner = 0
-- Números de línea
opt.number = true
opt.relativenumber = true
-- Plegado de código (arbol de syntax trees)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
-- Tabulaciones (2 espacios)
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Comportamiento del texto y comandos
opt.wrap = false
opt.smartindent = true
opt.inccommand = "split" -- muestra la búsqueda y reemplazo en vivo en otra ventana

-- Divisiones de pantalla (splits)
opt.splitbelow = true
opt.splitright = true

-- Búsqueda inteligente
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Barra de estado global (mini.statusline)
opt.laststatus = 3

-- Historial de deshacer persistente
opt.swapfile = false
opt.backup = false
opt.undofile = true -- necesario para que undodir funcione
opt.undodir = vim.fn.stdpath("data") .. "/undodir"

-- Portapapeles e interfaz
opt.clipboard = "unnamedplus"
opt.isfname:append("@-@")
opt.guicursor = "" -- mantiene el cursor del terminal sin estilos por modo
opt.scrolloff = 8 -- margen de 8 líneas arriba/abajo del cursor

opt.colorcolumn = "0"
opt.signcolumn = "yes"
opt.cmdheight = 0
opt.termguicolors = true -- imprescindible para los temas base16/moonfly

-- =========================================================
-- Autosave (conservador): guarda al terminar de escribir,
-- al cambiar de buffer y al perder el foco de la ventana.
-- Aplica a buffers reales modificables con nombre (incluye .tex:
-- vimtex/latexmk recompila con cada guardado).
-- Autocmds viven en core/autocmds.lua.
-- =========================================================
