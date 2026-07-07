-- =========================================================
-- Terminal Flotante y Ejecución de Comandos (runner-nvim)
-- =========================================================
local term_ok, toggleterm = pcall(require, "toggleterm")
if term_ok then
    toggleterm.setup({
        size = 20,
        open_mapping = [[<c-\>]], -- Un atajo global por si acaso
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        direction = "float", -- Mantiene la estética flotante que ya tenías
        float_opts = {
            border = "curved",
            winblend = 3,
        },
    })
    
    -- Replicar tu atajo anterior para que tu memoria muscular no sufra
    vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>", { desc = "Abrir Terminal Flotante" })
end
-- =========================================================
-- Decoraciones markdown (render_markdown) 
-- =========================================================
local render_ok, render_md = pcall(require, "render_markdown") 
if render_ok then 
  render_md.setup({
    -- soporte latex 
    latex = {enable = true}, 

    heading = {
      sign = false, 
      icons = { '󰎤 ', '󰎧 ', '󰎪 ', '󰎭 ', '󰎱 ', '󰎳 ' },
      width = "block", 
      min_width = 30
    }, 
    code = {
        enabled = true,
        render_modes = false,
        sign = true,
        conceal_delimiters = true,
        language = true,
        position = 'left',
        language_icon = true,
        language_name = true,
        language_info = true,
        language_pad = 0,
        disable = {},
        disable_background = { 'diff' },
        background_inset = 1,
        width = 'full',
        left_margin = 0,
        left_pad = 0,
        right_pad = 0,
        min_width = 0,
        border = 'hide',
        language_border = '█',
        language_left = '',
        language_right = '',
        above = '▄',
        below = '▀',
        inline = true,
        inline_left = '',
        inline_right = '',
        inline_pad = 0,
        priority = 140,
        highlight = 'RenderMarkdownCode',
        highlight_info = 'RenderMarkdownCodeInfo',
        highlight_language = nil,
        highlight_border = 'RenderMarkdownCodeBorder',
        highlight_fallback = 'RenderMarkdownCodeFallback',
        highlight_inline = 'RenderMarkdownCodeInline',
        highlight_inline_left = nil,
        highlight_inline_right = nil,
        style = 'full',
    }
  })
end 

-- =========================================================
-- Multiples cursores (multicursor.nvim)  
-- =========================================================
local mc_ok, mc = pcall(require, "multicursor-nvim")
if mc_ok then 
  mc.setup() 

  local set = vim.keymap.set 

  -- <Ctrl + n>: Añade un cursor a la siguiente coincidencia de la palabra bajo el cursor
  set({"n", "v"}, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Añadir cursor a coincidencia" })
  
  -- <Ctrl + s>: Salta la coincidencia actual y busca la siguiente (Skip)
  set({"n", "v"}, "<C-s>", function() mc.matchSkipCursor(1) end, { desc = "Saltar esta coincidencia" })

  -- <Ctrl + Flechas>: Añadir cursores directamente arriba o abajo
  set({"n", "v"}, "<C-Up>", function() mc.lineAddCursor(-1) end, { desc = "Añadir cursor arriba" })
  set({"n", "v"}, "<C-Down>", function() mc.lineAddCursor(1) end, { desc = "Añadir cursor abajo" })

  -- Reconfigurar <Esc> para limpiar los cursores cuando termines de editar
  set("n", "<Esc>", function()
      if mc.hasCursors() then
          mc.clearCursors()
      else
          -- Si no hay cursores, el comportamiento habitual de limpiar la búsqueda
          vim.cmd("nohlsearch") 
      end
  end, { desc = "Limpiar cursores" })
end


local zen_ok, zen = pcall(require, "zen-mode") 
local twilight_ok, twilight = pcall(require, "twilight") 

if twilight_ok then 
  twilight.setup({
    dimming = {
      alpha = 0.25
    },
  })
end
if zen_ok then
    zen.setup({
        window = {
            backdrop = 0.95, -- Oscurece ligeramente el fondo fuera de la zona de texto
            width = 100,     -- Ancho del texto centrado (ideal para leer LaTeX cómodamente)
            options = {
                number = true,         -- Oculta los números de línea
                relativenumber = true, -- Oculta los números relativos
            }
        },
        plugins = {
            -- Se integra con tus otras herramientas
            options = {
                enabled = true,
                twilight = true, -- ¡Enciende Twilight automáticamente al entrar al Modo Zen!
            },
        }
    })

    -- Atajo maestro: <leader>z para entrar/salir del Modo Zen
    vim.keymap.set("n", "<leader>z", function() 
        require("zen-mode").toggle() 
    end, { desc = "Alternar Modo Zen" })
end
