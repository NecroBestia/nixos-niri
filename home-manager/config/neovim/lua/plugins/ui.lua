return {
  -- Tema principal
  {
    "folke/tokyonight.nvim",
    lazy = false, -- Cargar inmediatamente al abrir
    priority = 1000, -- Máxima prioridad
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
  
  -- Iconos (Requerido por los demás)
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require('lualine').setup { options = { theme = 'tokyonight' } }
    end
  },

  -- Pestañas superiores (Bufferline)
  {
    "akinsho/bufferline.nvim",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup({
        options = {
          show_buffer_icons = true,
          mode = "tabs",
          diagnostics = "nvim_lsp",
          offsets = { { filetype = "NvimTree", text = "Explorador", text_align = "left", separator = true } }
        }
      })
    end
  },

  -- Explorador de archivos (Nvim-tree)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", ":NvimTreeToggle<CR>", desc = "Toggle file explorer", silent = true }
    },
    config = function()
      require('nvim-tree').setup({
        git = { ignore = false },
        update_focused_file = { enable = true, update_cwd = true },
      })
    end
  },

  -- Zen Mode
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>z", ":ZenMode<CR>", desc = "Toggle Zen Mode", silent = true }
    },
    config = function()
      require('zen-mode').setup({
        window = { width = 120, options = { number = true } },
        plugins = { lualine = { enable = true }, nvimtree = { enable = true, close = true } }
      })
    end
  }
}