{ pkgs, ... }:

{
  # ...el resto de tu configuración de home.nix...

  # Activa y configura Neovim
  programs.neovim = {
    enable = true;
    # Opcional: Hace que nvim sea el editor por defecto para 'vi', 'vim', etc.
    defaultEditor = true; 

    # --- 1. Aquí declaras tus plugins ---
    # Nix se encargará de descargarlos y gestionarlos.
    plugins = [
      # Un tema es solo otro plugin. Usemos "tokyonight" como ejemplo.
      pkgs.vimPlugins.tokyonight-nvim

      # Plugins básicos populares
      pkgs.vimPlugins.plenary-nvim    # Requerido por muchos plugins
      pkgs.vimPlugins.lualine-nvim    # Una barra de estado bonita
      pkgs.vimPlugins.telescope-nvim  # Fuzzy finder
      
      # Treesitter para resaltado de sintaxis avanzado
      # (Usamos 'withAllGrammars' para incluir todos los lenguajes)
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];

    # --- 2. Aquí va tu configuración (tu "init.lua") ---
    # Esto se escribe como un string de Nix.
    extraConfig = ''
      -- Opciones básicas de Neovim
      vim.opt.number = true         -- Mostrar números de línea
      vim.opt.relativenumber = true -- Números relativos
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true      -- Usar espacios en lugar de tabs
      vim.opt.hlsearch = true
      vim.opt.incsearch = true
      vim.g.mapleader = ' '         -- Establecer la tecla líder

      -- Cargar el tema que instalamos arriba
      vim.cmd.colorscheme "tokyonight"

      -- Configuración de ejemplo para lualine
      require('lualine').setup {
        options = {
          theme = 'tokyonight'
        }
      }

      -- Configuración de ejemplo para telescope
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    '';
  };
}
