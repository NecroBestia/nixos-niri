-- Definir teclas líder ANTES de cargar los plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("vim._core.ui2").enable({})

-- 1. Configuraciones base que no necesitan internet
require("core.options")
require("core.keymaps")

-- 2. EL GESTOR DE PAQUETES (El motor arranca aquí)
require("pack")

-- 3. Ahora que los paquetes existen, cargamos los módulos que dependen de ellos
require("core.treesitter")
require("core.lsp")

-- 4. El tema visual
vim.cmd.colorscheme("moonfly")