  -- Tema principal
  return{
  {
    "folke/tokyonight.nvim",
    lazy = false, -- Cargar inmediatamente al abrir
    priority = 1000, -- Máxima prioridad
    config = function()
      vim.cmd([[colorscheme vim]])
    end,
  },
  {
   "catppuccin/nvim", 
   lazy = false, 
   name = "catppuccin",
   priority = 1000, 
  }, 
  {
    "rebelot/kanagawa.nvim", 
    lazy = false, 
    name = "kanagawa",  
    priority = 1000, 
  }
}
