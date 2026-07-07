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
vim.keymap.set("n", "<leader>ff", function() 
    require("mini.pick").builtin.files({}, { source = { cwd = vim.fn.expand("~") } }) 
end, { desc = "Global search" })
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
-- Barra de Estado Inferior (mini.statusline)
-- =========================================================
local statusline = require("mini.statusline")
statusline.setup({
    use_icons = true,         -- Muestra los iconos de los lenguajes
    set_vim_settings = false, -- Evita conflictos con tus opciones globales
})

-- =========================================================
-- Gestor de Sesiones (mini.sessions)
-- =========================================================
local sessions = require("mini.sessions")
sessions.setup({
    autowrite = true, -- Guarda automáticamente la sesión actual antes de salir
    autoread = false, -- Evita cargar la última sesión de forma automática al abrir
})

-- =========================================================
-- Pantalla de Inicio (mini.starter)
-- =========================================================
local starter = require("mini.starter")
starter.setup({
    evaluate_single = true, -- Si el filtro deja una sola opción, la abre de inmediato
    
    items = {
        -- Conexión automática: Muestra tus últimas 5 sesiones guardadas
        starter.sections.sessions(5, true), 
        
        starter.sections.builtin_actions(),
        starter.sections.recent_files(5, false), -- Últimos 5 archivos globales
        starter.sections.recent_files(5, true),  -- Últimos 5 archivos en el directorio actual
        
        -- Acción rápida personalizada para iniciar limpio
        { name = 'Nuevo documento LaTeX', action = 'enew | set filetype=tex', section = 'Acciones Rápidas' },
    },
    
    content_hooks = {
        starter.gen_hook.adding_bullet("» "),
        starter.gen_hook.aligning('center', 'center'), -- Centra el menú en la pantalla
    },
})
-- =========================================================
-- Volver al Inicio (Guardar, Limpiar y Desconectar Sesión)
-- =========================================================
vim.keymap.set("n", "<leader>h", function()
    -- 1. Guardar y desconectar la sesión actual
    if vim.v.this_session ~= "" then
        require("mini.sessions").write() -- Guarda la estructura actual
        vim.v.this_session = ""          -- Rompe el enlace para que no se sobreescriba más
    end

    -- 2. Cerrar todos los buffers (archivos) abiertos para dejar el área limpia
    -- Usamos un escudo de seguridad: si no has guardado algo, abortará la limpieza
    local ok, _ = pcall(function() vim.cmd("%bd") end)
    if not ok then
        vim.notify("¡Alto! Tienes archivos sin guardar. Ejecuta :wa primero.", vim.log.levels.WARN)
        return
    end

    -- 3. Invocamos la pantalla de inicio sobre el editor limpio
    require("mini.starter").open()
end, { desc = "Ir al inicio y cerrar sesión" })
-- =========================================================
-- Integración Git (mini.diff y mini.git)
-- =========================================================
require("mini.diff").setup() -- Muestra los cambios (+, ~, -) de Git en el margen izquierdo
require("mini.git").setup()  -- Habilita comandos y utilidades base de Git
