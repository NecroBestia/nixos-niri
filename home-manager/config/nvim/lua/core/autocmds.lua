-- Autocmds globales (independientes de plugins).

-- Resaltar el texto recién yancado
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Autosave (conservador): guarda al terminar de escribir, al cambiar de
-- buffer y al perder el foco. Solo buffers reales modificables con nombre.
local autosave_group = vim.api.nvim_create_augroup("Autosave", { clear = true })
local function autosave_buf()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then return end -- terminal, help, etc.
  if not vim.bo[buf].modified then return end
  if not vim.bo[buf].modifiable or vim.bo[buf].readonly then return end
  if vim.fn.expand("%:p") == "" then return end -- buffer sin nombre
  vim.cmd("silent! write")
end
vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "FocusLost" }, {
  group = autosave_group,
  pattern = "*",
  callback = autosave_buf,
})
