-- =========================================================
-- Formateo: conform.nvim (<leader>f)
-- =========================================================
-- Orden: formatter CLI del filetype (tabla de abajo) → LSP con
-- capacidad de formato → aviso "Sin formatter".
-- Sin auto-format al guardar (decisión explícita).
--
-- Diagnóstico: :ConformInfo
--
-- Notas por herramienta:
--   - tex-fmt envuelve líneas a 80. Excluir bloques con
--     "% tex-fmt: off" ... "% tex-fmt: on".
--   - racketfmt necesita `raco pkg install fmt` (una vez).
--   - prolog usa `swipl formatter` (pack lsp_server del home).
--   - cl-indentify es wrapper propio: nixFlake/pkgs/cl-indentify.nix.
--   - sqlfluff: dialecto postgres por defecto; un .sqlfluff por
--     proyecto lo sobreescribe.
-- =========================================================
local conform = require("conform")

conform.setup({
  formatters_by_ft = {
    -- Sistemas y lenguajes de trabajo
    lua = { "stylua" },
    nix = { "nixfmt" },
    python = { "ruff_format" },
    rust = { "rustfmt" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    java = { "google-java-format" },
    go = { "gofmt" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },

    -- Documentación
    tex = { "tex-fmt" },
    markdown = { "prettier" },

    -- Web / datos
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    toml = { "taplo" },

    -- Otros lenguajes
    haskell = { "ormolu" },
    sql = { "sqlfluff" },
    prolog = { "prolog" },
    scheme = { "racketfmt" },
    racket = { "racketfmt" },
    lisp = { "cl-indentify" },
  },

  formatters = {
    -- sqlfluff solo formatea (no aplica fixes de lint) y con el
    -- dialecto que ya usábamos antes.
    -- El builtin exige un root marker (.sqlfluff, pyproject...,
    -- require_cwd=true); si no hay, usamos el dir del buffer.
    sqlfluff = {
      args = { "format", "--dialect", "postgres", "-" },
      require_cwd = false,
      cwd = function(self, ctx)
        local root = require("conform.util").root_file({
          ".sqlfluff",
          "pep8.ini",
          "pyproject.toml",
          "setup.cfg",
          "tox.ini",
        })(self, ctx)
        if root then return root end
        local name = vim.api.nvim_buf_get_name(ctx.buf)
        local dir = name ~= "" and vim.fs.dirname(name) or nil
        return (dir and dir ~= "") and dir or vim.fn.getcwd()
      end,
    },
    -- Wrapper propio sobre sbclPackages.cl-indentify (stdin → stdout).
    ["cl-indentify"] = {
      command = "cl-indentify",
      stdin = true,
    },
  },
})

local function buf_has_lsp_formatter()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    local caps = client.server_capabilities
    if caps.documentFormattingProvider or caps.documentRangeFormattingProvider then
      return true
    end
  end
  return false
end

vim.keymap.set("n", "<leader>f", function()
  -- Si el filetype no tiene CLI ni LSP, avisamos nosotros. Si tiene
  -- CLI configurado pero su binario falta, conform.format() avisa
  -- con el motivo exacto ("Formatter 'x' unavailable: ...").
  if #conform.list_formatters_for_buffer(0) == 0 and not buf_has_lsp_formatter() then
    vim.notify(
      "Sin formatter para " .. (vim.bo.filetype ~= "" and vim.bo.filetype or "?"),
      vim.log.levels.INFO
    )
    return
  end
  conform.format({ async = true, lsp_format = "fallback", timeout_ms = 5000 })
end, { desc = "Format buffer (CLI por filetype o LSP)" })
