-- =========================================================
-- Edición: terminal flotante, múltiples cursores y mini.surround
-- =========================================================

-- Terminal flotante (toggleterm)
local term_ok, toggleterm = pcall(require, "toggleterm")
if term_ok then
  toggleterm.setup({
    size = 20,
    open_mapping = [[<c-\>]], -- atajo global por si acaso
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    direction = "float", -- estética flotante
    float_opts = {
      border = "curved",
      winblend = 3,
    },
  })
  vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>", { desc = "Abrir Terminal Flotante" })
end

-- Múltiples cursores (multicursor.nvim)
local mc_ok, mc = pcall(require, "multicursor-nvim")
if mc_ok then
  mc.setup()

  local set = vim.keymap.set

  -- <Ctrl + n>: añade un cursor a la siguiente coincidencia de la palabra bajo el cursor
  set({ "n", "v" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Añadir cursor a coincidencia" })

  -- <Ctrl + s>: salta la coincidencia actual y busca la siguiente
  set({ "n", "v" }, "<C-s>", function() mc.matchSkipCursor(1) end, { desc = "Saltar esta coincidencia" })

  -- <Ctrl + Flechas>: añadir cursores directamente arriba o abajo
  set({ "n", "v" }, "<C-Up>", function() mc.lineAddCursor(-1) end, { desc = "Añadir cursor arriba" })
  set({ "n", "v" }, "<C-Down>", function() mc.lineAddCursor(1) end, { desc = "Añadir cursor abajo" })

  -- <Esc> limpia los cursores al terminar; si no hay cursores, actúa como
  -- nohlsearch. Nota: esto sobreescribe el no-op nativo de <Esc> en modo normal.
  set("n", "<Esc>", function()
    if mc.hasCursors() then
      mc.clearCursors()
    else
      vim.cmd("nohlsearch")
    end
  end, { desc = "Limpiar cursores" })
end

-- mini.surround: añadir/quitar/reemplazar comillas y brackets
-- (sa/sd/sr/sf/sF/sh + s<lnum> para saltar)
local surround_ok, surround = pcall(require, "mini.surround")
if surround_ok then
  surround.setup()
end
