-- Explorador de archivos
local MiniFiles = require("mini.files")
MiniFiles.setup({ mappings = { go_in = "<CR>", go_in_plus = "L", go_out = "_", go_out_plus = "H" } })
vim.keymap.set("n", "-", "<cmd>lua MiniFiles.open()<CR>", { desc = "Toggle mini file explorer" })

-- Interfaz base
require("mini.notify").setup({ content = { format = function(notif) return notif.msg end } })
require("mini.cmdline").setup({ autocorrect = { enable = false } })
require("mini.surround").setup()

-- Buscador (Picker)
local MiniPick = require("mini.pick")
local MiniExtra = require("mini.extra")
MiniPick.setup()
MiniExtra.setup()

vim.keymap.set("n", "<leader>pf", function() MiniPick.builtin.files() end, { desc = "Mini File Picker" })
vim.keymap.set("n", "<leader>ps", function() MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") }) end, { desc = "Grep word/Search word" })
vim.keymap.set("n", "<leader>vh", function() MiniPick.builtin.help() end, { desc = "Mini Help" })

-- Autocompletado
require("mini.completion").setup({ lsp_completion = { auto_setup = true } })

-- Snippets y Atajos Matemáticos (Formato TextMate)
local MiniSnippets = require("mini.snippets")

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

-- Integración Git
require("mini.diff").setup({ source = require("mini.diff").gen_source.git({ index = false }) })