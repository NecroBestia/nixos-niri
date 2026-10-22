-- =========================================================
-- Treesitter: parsers (gramáticas compiladas) y arranque por filetype.
--
-- - install() va en pcall: en el primer arranque sin red (o si un
--   grammar falla al compilar) el inicio no se rompe.
-- - Los parsers ya compilados viven en
--   ~/.local/share/nvim/site/parser/ (gestiona nvim-treesitter main).
-- - El FileType autocmd arranca el parser por buffer si existe; para
--   filetypes sin treesitter sale temprano (get_lang nil).
-- =========================================================
local ts_ok, treesitter = pcall(require, "nvim-treesitter")
if not ts_ok then
  vim.notify("nvim-treesitter no está en runtimepath", vim.log.levels.ERROR)
  return
end

-- 'markdown_inline' es un parser aparte (mismo repo de grammar): sin él,
-- render-markdown.nvim pierde el resaltado inline ("full highlighting").
local ensure_installed = {
    -- Lenguajes del sistema y desarrollo
    "c", "cpp", "python", "nix", "rust", "go",
    -- Web y shell
    "bash", "lua", "vim", "vimdoc",
    -- Documentación
    "latex", "markdown", "markdown_inline",
    -- Bases de datos y lenguajes lógicos/funcionales
    "sql", "scheme", "prolog", "haskell",
}

pcall(treesitter.install, ensure_installed)

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    local buf = args.buf
    local ft = vim.bo[buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if not lang then return end
    local ok_add = pcall(vim.treesitter.language.add, lang)
    if not ok_add then return end
    pcall(vim.treesitter.start, buf, lang)
  end,
})
