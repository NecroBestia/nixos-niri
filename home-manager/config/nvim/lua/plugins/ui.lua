-- =========================================================
-- Interfaz: mini.ecosistema (files, pick, statusline, tabline,
-- icons, notify, cmdline, starter, sessions)
-- (completion/snippets → plugins/completion.lua; diff/git → plugins/git.lua;
--  surround → plugins/editor.lua)
-- =========================================================

-- ---------------------------------------------------------
-- Explorador de archivos (mini.files)
-- ---------------------------------------------------------
local ok_files, MiniFiles = pcall(require, "mini.files")
if ok_files then
  MiniFiles.setup({ mappings = { go_in = "<CR>", go_in_plus = "L", go_out = "_", go_out_plus = "H" } })
  vim.keymap.set("n", "-", function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then return MiniFiles.open() end

    local function check_path(p)
      if not p or p == "" or p == "/" then
        return vim.schedule(function() MiniFiles.open() end)
      end

      vim.uv.fs_stat(p, function(err, stat)
        if not err and stat then
          vim.schedule(function() MiniFiles.open(p) end)
        else
          check_path(vim.fs.dirname(p))
        end
      end)
    end

    check_path(path)
  end, { desc = "Toggle mini file explorer (async safe)" })

  -- Abrir el archivo en un split nuevo (receta oficial de la doc de mini.files)
  local map_split = function(buf_id, lhs, direction)
    local rhs = function()
      local cur_target = MiniFiles.get_explorer_state().target_window
      local new_target = vim.api.nvim_win_call(cur_target, function()
        vim.cmd(direction .. " split")
        return vim.api.nvim_get_current_win()
      end)
      MiniFiles.set_target_window(new_target)
      MiniFiles.go_in({ close_on_file = true })
    end
    vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = "Abrir en split " .. direction })
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      local buf_id = args.data.buf_id
      -- Ctrl + v abre el archivo a la derecha (vertical)
      map_split(buf_id, "<C-v>", "belowright vertical")
      -- Ctrl + x abre el archivo abajo (horizontal)
      map_split(buf_id, "<C-x>", "belowright horizontal")
    end,
  })
end

-- ---------------------------------------------------------
-- Iconos y pestañas de buffers
-- ---------------------------------------------------------
local ok_icons, icons = pcall(require, "mini.icons")
if ok_icons then icons.setup() end

local ok_tabline, tabline = pcall(require, "mini.tabline")
if ok_tabline then tabline.setup({ show_icons = true }) end

-- ---------------------------------------------------------
-- Notificaciones y cmdline
-- ---------------------------------------------------------
local ok_notify, notify = pcall(require, "mini.notify")
if ok_notify then
  notify.setup({ content = { format = function(notif) return notif.msg end } })
end
local ok_cmdline, cmdline = pcall(require, "mini.cmdline")
if ok_cmdline then cmdline.setup({ autocorrect = { enable = false } }) end

-- ---------------------------------------------------------
-- Buscador (mini.pick + mini.extra): archivos, grep, help
-- ---------------------------------------------------------
local ok_pick, MiniPick = pcall(require, "mini.pick")
if ok_pick then
  local ok_extra, extra = pcall(require, "mini.extra")
  if ok_extra then extra.setup() end
  MiniPick.setup()

  -- Un cwd por picker:
  --   <leader>ff → disco principal (home ~)
  --   <leader>fm → /mnt/not_to_lose (montaje de datos)
  vim.keymap.set("n", "<leader>ff", function()
    MiniPick.builtin.files({}, { source = { cwd = vim.fn.expand("~") } })
  end, { desc = "Buscar archivos en ~ (disco principal)" })
  vim.keymap.set("n", "<leader>fm", function()
    MiniPick.builtin.files({}, { source = { cwd = "/mnt/not_to_lose" } })
  end, { desc = "Buscar archivos en /mnt/not_to_lose" })

  vim.keymap.set("n", "<leader>fg", function() MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") }) end,
    { desc = "Live Grep Word (mini.pick)" })
  vim.keymap.set("n", "<leader>vh", function() MiniPick.builtin.help() end, { desc = "Help Tags (mini.pick)" })
end

-- ---------------------------------------------------------
-- Barra de estado
-- ---------------------------------------------------------
local ok_statusline, statusline = pcall(require, "mini.statusline")
if ok_statusline then
  statusline.setup({
    use_icons = true, -- iconos de lenguaje
    set_vim_settings = false, -- sin tocar opciones globales
  })
end

-- ---------------------------------------------------------
-- Gestor de sesiones
-- ---------------------------------------------------------
local ok_sessions, sessions = pcall(require, "mini.sessions")
if ok_sessions then
  sessions.setup({
    autowrite = true, -- guarda la sesión actual antes de salir
    autoread = false, -- NO carga la última sesión automáticamente
  })
end

-- ---------------------------------------------------------
-- Pantalla de inicio (mini.starter)
-- ---------------------------------------------------------
local ok_starter, starter = pcall(require, "mini.starter")
if ok_starter then
  starter.setup({
    evaluate_single = true, -- si el filtro deja una sola opción, la abre

    items = {
      -- Últimas 5 sesiones guardadas
      starter.sections.sessions(5, true),
      starter.sections.builtin_actions(),
      starter.sections.recent_files(5, false), -- últimos 5 archivos globales
      starter.sections.recent_files(5, true), -- últimos 5 en el cwd

      -- Acción rápida para iniciar limpio
      { name = "Nuevo documento LaTeX", action = "enew | set filetype=tex", section = "Acciones Rápidas" },
    },

    content_hooks = {
      starter.gen_hook.adding_bullet("» "),
      starter.gen_hook.aligning("center", "center"),
    },
  })

  -- <leader>h: guardar/desconectar sesión, cerrar terminales y buffers,
  -- y volver a la pantalla de inicio.
  vim.keymap.set("n", "<leader>h", function()
    if vim.v.this_session ~= "" then
      require("mini.sessions").write()
      vim.v.this_session = ""
    end

    local ok_tt, tt = pcall(require, "toggleterm")
    if ok_tt then
      tt.toggle_all(true) -- cierre forzado
    end

    -- sin chequeo de modificados: autosave + force evitan E37
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end

    require("mini.starter").open()
  end, { desc = "Ir al inicio y cerrar sesión" })
end
