-- Definir teclas líder ANTES de cargar los plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("vim._core.ui2").enable({})

require("core.options")
require("core.keymaps")
require("core.treesitter")
require("core.lsp")

require("pack")   

vim.cmd.colorscheme("tokyonight")