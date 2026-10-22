-- Atajos globales (independientes de plugins).
vim.g.mapleader = " "

vim.keymap.set("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "<C-c>", ":nohl<CR>", { desc = "Clear search highlighting", silent = true })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result cursor centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result cursor centered" })

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word cursor is on globally" })
vim.keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" })

vim.keymap.set("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart config (:restart)" })

-- native undotree (plugin dist de 0.12, opt/)
vim.keymap.set("n", "<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  require("undotree").open()
end, { desc = "Toggle Builtin Undotree" })

-- Shift + h (buffer anterior)
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Buffer anterior" })

-- Shift + l (buffer siguiente)
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Buffer siguiente" })

-- Shift + w (cerrar el buffer actual)
vim.keymap.set("n", "<S-w>", "<cmd>bdelete<CR>", { desc = "Cerrar buffer" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Salir modo terminal" })

-- LaTeX (vimtex; opciones en plugins/latex.lua)
vim.keymap.set("n", "<leader>lc", "<cmd>VimtexCompile<CR>", { desc = "Compilar LaTeX" })
vim.keymap.set("n", "<leader>lv", "<cmd>VimtexView<CR>", { desc = "Abrir PDF en Zathura (salta a la posición del cursor)" })
vim.keymap.set("n", "<leader>le", "<cmd>VimtexErrors<CR>", { desc = "Mostrar errores LaTeX" })
vim.keymap.set("n", "<leader>me", function()
  local ok, err = pcall(function() require("nabla").popup() end)
  if not ok then
    vim.notify("nabla: " .. tostring(err), vim.log.levels.ERROR)
  end
end, { desc = "Previsualizar ecuación LaTeX" })
