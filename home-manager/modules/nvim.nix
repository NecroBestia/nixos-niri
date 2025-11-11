{ pkgs, ... }:

{
  # ...

  programs.neovim = {
    enable = true;
    defaultEditor = true; 

    plugins = with pkgs; [
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
    vimPlugins.bufferline-nvim
    vimPlugins.mason-lspconfig-nvim 
    vimPlugins.mason-nvim           
    vimPlugins.nvim-web-devicons     
  ];
  extraPackages = with pkgs; [
    nodejs
    unzip
    cargo
    gcc
    rustc
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
    
    -- Cargar el tema
    vim.cmd.colorscheme "tokyonight"

    -- ---  CONFIGURACIÓN DE ICONOS ---
    -- (Debe ir antes que lualine, bufferline y nvim-tree)
    require('nvim-web-devicons').setup() 

    -- ---  PLUGINS DE INTERFAZ (UI) ---

    -- Lualine (Barra de estado)
    require('lualine').setup {
      options = {
        theme = 'tokyonight'
      }
    }

    -- Nvim-Tree (Explorador de archivos)
    require('nvim-tree').setup({
      git = {
        ignore = false,
      },
      update_focused_file = {
        enable = true,
        update_cwd = true,
      },
    })
    vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', {
      silent = true, desc = 'Toggle file explorer tree'
    })

    -- Zen-Mode (Modo sin distracciones)
    require('zen-mode').setup({
      window = {
        width = 120, 
        options = {
          number = true,
          relativenumber = false,
        }
      },
      plugins = {
        lualine = { enable = true },
        nvimtree = { enable = true, close = true },
      }
    })
    vim.keymap.set('n', '<leader>z', ':ZenMode<CR>', {
      silent = true, desc = 'Toggle Zen Mode'
    })

    -- Bufferline (Pestañas)
    require('bufferline').setup({
      options = {
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        diagnostics = "nvim_lsp",
        mode = "tabs", 
        offsets = {
          {
            filetype = "NvimTree",
            text = "Explorador de Archivos",
            text_align = "left",
            separator = true
          }
        }
      }
    })

    -- ---  PLUGINS DE FUNCIONALIDAD ---

    -- Telescope (Buscador)
    local telescope = require('telescope')
    local actions = require('telescope.actions')
    local builtin = require('telescope.builtin')

    -- Atajos para ABRIR telescope
    vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    
    -- Configuración INTERNA de telescope (para Ctrl+t)
    telescope.setup({
      defaults = {
        mappings = {
          i = { -- Modo Inserción (mientras buscas)
            ["<CR>"] = actions.select_default,
            ["<C-t>"] = actions.select_tab, -- <-- Abrir en pestaña
          }
        }
      }
    })

    -- ---  LSP, MASON Y AUTOCOMPLETADO ---

    -- Cmp (Autocompletado)
    local cmp = require('cmp')
    local lspconfig = require('lspconfig')
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
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
      }),
    })

    -- LspConfig (Función 'on_attach' con atajos)
    local on_attach = function(client, bufnr)
      local opts = { noremap=true, silent=true, buffer=bufnr }
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    end

    -- Mason (El instalador)
    require('mason').setup()
    
    -- Mason-LSPConfig (El "pegamento")
    require('mason-lspconfig').setup({
      ensure_installed = { 
        "pyright", 
        "nil_ls", 
        "rust_analyzer",
        "clangd"
      }
    })

    -- El "Pegamento" Mágico
    -- Conecta Mason con LSPConfig, usando tu 'on_attach' y 'capabilities'
    require('mason-lspconfig').setup_handlers {
      function (server_name) -- El handler por defecto
        lspconfig[server_name].setup {
          on_attach = on_attach,
          capabilities = capabilities, -- <-- Muy importante para cmp
        }
      end,
    }
  '';
        
  };
}
