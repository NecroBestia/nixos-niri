return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      -- 1. Carga segura principal
      local ok, lspconfig = pcall(require, "lspconfig")
      if not ok then return end

      -- Carga segura del autocompletado
      local cmp_ok, cmp = pcall(require, 'cmp')
      if not cmp_ok then return end

      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- 2. Configuración del menú emergente de Autocompletado
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

      -- 3. Atajos de teclado exclusivos para cuando programas
      local on_attach = function(client, bufnr)
        local opts = { noremap=true, silent=true, buffer=bufnr }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
      end

      -- 4. Conexión de Servidores (La sintaxis nativa del futuro: Neovim 0.12+)
      vim.lsp.config['clangd'] = { on_attach = on_attach, capabilities = capabilities, cmd = { "clangd", "--background-index" } }
      vim.lsp.enable('clangd')

      vim.lsp.config['pyright'] = { on_attach = on_attach, capabilities = capabilities }
      vim.lsp.enable('pyright')

      vim.lsp.config['nil_ls'] = { on_attach = on_attach, capabilities = capabilities }
      vim.lsp.enable('nil_ls')

      vim.lsp.config['rust_analyzer'] = { on_attach = on_attach, capabilities = capabilities }
      vim.lsp.enable('rust_analyzer')
    end
  }
}