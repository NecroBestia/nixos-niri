-- Definir teclas líder ANTES de cargar los plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Cargar configuración base
require("core.options")
require("core.keymaps")

-- Instalar automáticamente lazy.nvim si no existe en el sistema
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Iniciar Lazy y decirle que busque configuraciones en la carpeta "lua/plugins/"
require("lazy").setup("plugins")