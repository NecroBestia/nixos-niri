{ pkgs, ... }:

{
  # ...

  programs.neovim = {
    enable = true;
    defaultEditor = true; 

    plugins = with pkgs; [
      # Tus plugins (esto estaba bien)
      vimPlugins.tokyonight-nvim
      vimPlugins.plenary-nvim
      vimPlugins.lualine-nvim
      vimPlugins.telescope-nvim
      vimPlugins.nvim-treesitter.withAllGrammars
      vimPlugins.nvim-tree-lua
      vimPlugins.zen-mode-nvim
      vimPlugins.nvim-lspconfig
      vimPlugins.nvim-cmp
      vimPlugins.cmp-nvim-lsp
      vimPlugins.cmp-buffer
      vimPlugins.cmp-path
  ];
      
    extraLuaConfig = ''
      -- Opciones básicas de Neovim
      vim.opt.number = true         -- Mostrar números de línea
      vim.opt.relativenumber = true -- Números relativos
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true      -- Usar espacios en lugar de tabs
      vim.opt.hlsearch = true
      vim.opt.incsearch = true
      vim.g.mapleader = ' '         -- Establecer la tecla líder
      vim.opt.clipboard = 'unnamedplus' -- Usa el portapapeles del sistema
           -- Cargar el tema que instalamos arriba
      vim.cmd.colorscheme "tokyonight"

      -- Configuración de ejemplo para lualine
      require('lualine').setup {
        options = {
          theme = 'tokyonight'
        }
      }
      -- Activa el plugin nvim-tree-lua
        require('nvim-tree').setup({
          -- Opcional: git.ignore = false para ver archivos ignorados por git
          git = {
            ignore = false,
          },
          -- Opcional: Actualiza el "directorio raíz" al abrir/cerrar
          update_focused_file = {
            enable = true,
            update_cwd = true,
          },
        })

      -- Atajo de teclado para abrir/cerrar el árbol
      -- <leader>e (Espacio + e)
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', {
        silent = true,
        desc = 'Toggle file explorer tree'
      })
      -- Activa el plugin zen-mode
      require('zen-mode').setup({
        window = {
          -- Ancho de la ventana centrada (puedes ajustarlo)
          width = 120, 
          options = {
            -- Ocultar números de línea en modo zen
            number = true,
            relativenumber = false,
          }
        },
        plugins = {
          -- Ocultar lualine automáticamente
          lualine = { enable = true },
          -- Cerrar nvim-tree automáticamente
          nvimtree = { enable = true, close = true },
        }
      })

      -- Atajo de teclado para activar/desactivar
      -- <leader>z (Espacio + z)
      vim.keymap.set('n', '<leader>z', ':ZenMode<CR>', {
        silent = true,
        desc = 'Toggle Zen Mode'
      })
      -- Configuración de ejemplo para telescope
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      local cmp = require('cmp')
      local lspconfig = require('lspconfig') -- <-- Esto es correcto
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      cmp.setup({
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' }
        }),
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          -- ...otros mappings...
        }),
      })

      local on_attach = function(client, bufnr)
        local opts = { noremap=true, silent=true, buffer=bufnr }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      end

      -- Activa tus servidores (Recuerda añadirlos a home.packages)
      lspconfig.pyright.setup{
        on_attach = on_attach,
        capabilities = capabilities
      }
      lspconfig.nil_ls.setup{
        on_attach = on_attach,
        capabilities = capabilities
      }

    '';
  };
}
