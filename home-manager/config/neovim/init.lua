-- Definir teclas líder ANTES de cargar los plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("vim._core.ui2").enable({})

require("options")
require("keymaps")
require("pack")   
require("treesitter")
require("lsp")

vim.cmd.colorscheme("tokyonight")