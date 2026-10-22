-- =========================================================
-- Concentración: zen-mode (ventana centrada) + twilight (atenúa
-- el código fuera del bloque actual).
-- =========================================================
-- FIX twilight en Neovim 0.12 —
-- `vim.treesitter.get_parser()` ahora devuelve nil en vez de lanzar
-- error cuando no puede crear el parser (treesitter.lua:74 del runtime
-- 0.12). El guard de twilight (`pcall(vim.treesitter.get_parser, buf)`,
-- view.lua:168) por eso cuenta como exito aunque el parser no exista,
-- y view.get_node crashea al indexarlo ("attempt to index local
-- 'parser'") en TODO buffer sin parser, en cada WinEnter/CursorMoved.
--
-- Los autocmds de twilight resuelven por la tabla del módulo al
-- dispararse (strings "lua require('twilight.view').update", view.lua
-- 17-20), de modo que este wrap en caliente intercepta todo el flujo
-- sin tocar plugin-files. No sirve `treesitter = false`: el fallback
-- M.expand también llama get_node (view.lua:137).
--
-- Resultado: buffers con parser → dimming normal; buffers sin parser
-- → update es no-op silencioso en vez de error.
local zen_ok, zen = pcall(require, "zen-mode")
local twi_ok, twilight = pcall(require, "twilight")

if twi_ok then
  twilight.setup({
    dimming = { alpha = 0.25 },
  })

  local view = require("twilight.view")
  local function safe(fn)
    return function(...)
      pcall(fn, ...)
    end
  end
  view.update = safe(view.update)
  view.on_win_enter = safe(view.on_win_enter)
end

if zen_ok then
  zen.setup({
    window = {
      backdrop = 0.95, -- oscurece un poco el fondo fuera del texto
      width = 100, -- ancho del texto centrado (ideal para leer LaTeX)
      options = {
        number = true,
        relativenumber = true,
      },
    },
    plugins = {
      options = { enabled = true },
      twilight = { enabled = true },
    },
  })

  -- Atajo maestro: entrar/salir del Modo Zen
  vim.keymap.set("n", "<leader>z", function()
    require("zen-mode").toggle()
  end, { desc = "Alternar Modo Zen" })
end
