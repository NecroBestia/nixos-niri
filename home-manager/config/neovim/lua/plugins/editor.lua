return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", -- Ordena compilar las gramáticas al instalar
    config = function()
      require('nvim-treesitter.configs').setup({
        -- Idiomas a compilar automáticamente
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "nix", "python", "rust", "cpp" },
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
      })
    end
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fn", function() require('telescope.builtin').find_files({cwd = '/mnt/not-to-lose/SyncThing/Universidad/'}) end, desc = "Buscar en Universidad" }
    },
    config = function()
      require('telescope').setup({
        defaults = {
          mappings = {
            i = { ["<C-t>"] = require('telescope.actions').select_tab }
          }
        }
      })
    end
  }
}