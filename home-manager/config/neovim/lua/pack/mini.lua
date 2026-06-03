-- =========================================================
-- Explorador de archivos (mini.files)
-- =========================================================
local MiniFiles = require("mini.files")
MiniFiles.setup({ mappings = { go_in = "<CR>", go_in_plus = "L", go_out = "_", go_out_plus = "H" } })
vim.keymap.set("n", "-", "<cmd>lua MiniFiles.open()<CR>", { desc = "Toggle mini file explorer" })

-- Superpoderes para MiniFiles: Abrir en Pantalla Dividida
local map_split = function(buf_id, lhs, direction)
  local rhs = function()
    local cur_target = MiniFiles.get_explorer_state().target_window
    local new_target = vim.api.nvim_win_call(cur_target, function()
      vim.cmd(direction .. ' split')
      return vim.api.nvim_get_current_win()
    end)
    MiniFiles.set_target_window(new_target)
    MiniFiles.go_in({ close_on_file = true })
  end
  vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = 'Abrir en split ' .. direction })
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id
    -- Ctrl + v abre el archivo a la derecha (Vertical)
    map_split(buf_id, '<C-v>', 'belowright vertical')
    -- Ctrl + x abre el archivo abajo (Horizontal)
    map_split(buf_id, '<C-x>', 'belowright horizontal')
  end,
})

-- =========================================================
-- Pestañas e Iconos (Reemplazo de Bufferline)
-- =========================================================
require("mini.icons").setup()
require("mini.tabline").setup({ show_icons = true })

-- =========================================================
-- Interfaz base
-- =========================================================
require("mini.notify").setup({ content = { format = function(notif) return notif.msg end } })
require("mini.cmdline").setup({ autocorrect = { enable = false } })
require("mini.surround").setup()

-- =========================================================
-- Buscador (Reemplazo de Telescope)
-- =========================================================
local MiniPick = require("mini.pick")
local MiniExtra = require("mini.extra")
MiniPick.setup()
MiniExtra.setup()

-- Manteniendo tus atajos clásicos de Telescope
vim.keymap.set("n", "<leader>ff", function() MiniPick.builtin.files() end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function() MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") }) end, { desc = "Live Grep Word" })
vim.keymap.set("n", "<leader>vh", function() MiniPick.builtin.help() end, { desc = "Help Tags" })

-- =========================================================
-- Autocompletado y Snippets
-- =========================================================
require("mini.completion").setup({ lsp_completion = { auto_setup = true } })

local MiniSnippets = require("mini.snippets")

-- Atajos Matemáticos (Listos para Series Numéricas y Polares)
local math_snippets = {
    tex = {
        serie = { body = "\\sum_{n=${1:1}}^{\\infty} ${2:a_n}" },
        intimp = { body = "\\int_{${1:a}}^{\\infty} ${2:f(x)}\\, dx" },
        polar = { body = "x = r \\cos(\\theta) \\\\\ny = r \\sin(\\theta)" },
    }
}

MiniSnippets.setup({
    snippets = {
        MiniSnippets.gen_loader.from_lang(), 
        function(context)
            local lang = vim.bo[context.buf_id].filetype
            local snips = math_snippets[lang] or {}
            local res = {}
            for k, v in pairs(snips) do
                table.insert(res, { prefix = k, body = v.body })
            end
            return res
        end,
    },
})
MiniSnippets.start_lsp_server({ match = false })

-- =========================================================
-- Integración Git
-- =========================================================
require("mini.diff").setup({ source = require("mini.diff").gen_source.git({ index = false }) })
