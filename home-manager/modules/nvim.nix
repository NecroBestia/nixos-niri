{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # --- 1. PLUGINS (Instalados por Nix) ---
    plugins = with pkgs.vimPlugins; [
      tokyonight-nvim
      plenary-nvim
      lualine-nvim
      telescope-nvim
      
      # Treesitter
      nvim-treesitter.withAllGrammars
      
      nvim-tree-lua
      zen-mode-nvim
      
      # LSP y Autocompletado
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      bufferline-nvim
      
      # Iconos
      nvim-web-devicons
      
      # NOTA: Se eliminaron los plugins de Mason para evitar conflictos
    ];

    # --- 2. PAQUETES EXTERNOS (Binarios del sistema) ---
    extraPackages = with pkgs; [
      # Herramientas base
      nodejs
      unzip
      cargo
      gcc
      rustc
      fd
      ripgrep
      xclip 

      # --- LSPs NATIVOS ---
      clang-tools   # C/C++ (clangd)
      nil           # Nix
      pyright       # Python
      rust-analyzer # Rust
    ];

    # --- 3. CONFIGURACIÓN LUA ---
    extraLuaConfig = ''
      -- Opciones básicas
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.hlsearch = true
      vim.opt.incsearch = true
      vim.g.mapleader = ' '
      vim.opt.clipboard = 'unnamedplus'
      
      -- Tema
      vim.cmd.colorscheme "tokyonight"

      -- Iconos
      require('nvim-web-devicons').setup()

      -- --- TREESITTER ---
      require('nvim-treesitter.configs').setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
      })

      -- --- UI ---
      require('lualine').setup { options = { theme = 'tokyonight' } }

      require('nvim-tree').setup({
        git = { ignore = false },
        update_focused_file = { enable = true, update_cwd = true },
      })
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true, desc = 'Toggle file explorer' })

      require('zen-mode').setup({
        window = { width = 120, options = { number = true } },
        plugins = { lualine = { enable = true }, nvimtree = { enable = true, close = true } }
      })
      vim.keymap.set('n', '<leader>z', ':ZenMode<CR>', { silent = true, desc = 'Toggle Zen Mode' })

      require('bufferline').setup({
        options = {
          show_buffer_icons = true,
          mode = "tabs",
          diagnostics = "nvim_lsp",
          offsets = { { filetype = "NvimTree", text = "Explorador", text_align = "left", separator = true } }
        }
      })

      -- --- TELESCOPE ---
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fn', function () 
        builtin.find_files({cwd = '/mnt/not-to-lose/SyncThing/Universidad/' })
      end, {desc = 'Buscar en Universidad'})
      
      require('telescope').setup({
        defaults = {
          mappings = {
            i = { ["<C-t>"] = require('telescope.actions').select_tab }
          }
        }
      })

      -- --- LSP Y AUTOCOMPLETADO ---
      
      local cmp = require('cmp')
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

      local on_attach = function(client, bufnr)
        local opts = { noremap=true, silent=true, buffer=bufnr }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
      end

      -- CONFIGURACIÓN LSP (Modo Nuevo / Sin Deprecation)
      -- Usamos vim.lsp.config directamente en lugar del framework antiguo

      -- 1. Clangd (C/C++)
      vim.lsp.config['clangd'] = {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = { "clangd", "--background-index" }
      }
      vim.lsp.enable('clangd')

      -- 2. Python (Pyright)
      vim.lsp.config['pyright'] = {
        on_attach = on_attach,
        capabilities = capabilities,
      }
      vim.lsp.enable('pyright')

      -- 3. Nix (Nil)
      vim.lsp.config['nil_ls'] = {
        on_attach = on_attach,
        capabilities = capabilities,
      }
      vim.lsp.enable('nil_ls')
      
      -- 4. Rust (Rust Analyzer)
      vim.lsp.config['rust_analyzer'] = {
        on_attach = on_attach,
        capabilities = capabilities,
      }
      vim.lsp.enable('rust_analyzer')
    '';
  };
}
