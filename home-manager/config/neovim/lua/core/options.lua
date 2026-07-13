local opt = vim.opt

-- Desactiva el banner molesto del explorador de archivos nativo
vim.g.netrw_banner = 0
-- Números de línea
opt.number = true
opt.relativenumber = true
-- Plegado codigo 
opt.foldmethod = "expr" 
opt.foldexpr = " v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
-- Tabulaciones (2 espacios)
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Comportamiento del texto y comandos
opt.wrap = false 
opt.smartindent = true 
opt.inccommand = "split" -- Muestra la búsqueda y reemplazo en vivo en otra ventana

-- Divisiones de pantalla (splits)
opt.splitbelow = true 
opt.splitright = true 

-- Búsqueda inteligente
opt.ignorecase = true 
opt.smartcase = true 
opt.hlsearch = true
opt.incsearch = true

-- Barra de estado global (Lualine)
opt.laststatus = 3 

-- Historial de deshacer persistente (¡Una joya!)
opt.swapfile = false
opt.backup = false
opt.undofile = true -- Necesario para que undodir funcione
opt.undodir = vim.fn.stdpath("data") .. "/undodir"

-- Portapapeles e Interfaz
opt.clipboard = 'unnamedplus'
opt.isfname:append("@-@")
opt.guicursor = ""
opt.scrolloff = 8 -- Mantiene siempre 8 líneas de margen arriba/abajo del cursor

opt.colorcolumn = "0"
opt.signcolumn = "yes"
opt.cmdheight = 0 
opt.termguicolors = true -- Vital para que Tokyonight se vea bien

-- Resaltar texto al copiar (Yank)
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking text",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
})
