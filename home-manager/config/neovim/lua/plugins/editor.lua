return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    -- Esto asegura que el plugin se cargue después de que Lazy esté listo
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        return
      end
      configs.setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "nix", "python", "rust", "cpp" },
        highlight = { enable = true },
      })
    end,
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