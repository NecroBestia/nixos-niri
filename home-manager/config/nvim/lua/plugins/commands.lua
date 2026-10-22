-- Atajos de vim.pack. Ojo: vim.pack.add exige URL completa
-- (la forma corta "user/repo" no es válida según lua/vim/pack.lua).
vim.api.nvim_create_user_command("PackAdd", function(opts)
  vim.pack.add(opts.fargs)
end, { nargs = "+", desc = "Add plugins (:PackAdd https://github.com/user/repo ...)" })

vim.api.nvim_create_user_command("PackDel", function(opts)
  vim.pack.del(opts.fargs)
end, { nargs = "+", desc = "Delete plugins (:PackDel plugin1 plugin2)" })

vim.api.nvim_create_user_command("PackUpdate", function(opts)
  if opts.args:match("%S") then
    local names = vim.split(opts.args, "%s+", { trimempty = true })
    vim.pack.update(names)
  else
    vim.pack.update()
  end
end, { nargs = "*", desc = "Update all plugins or specific ones" })
