-- =========================================================
-- Git: mini.diff (marcas +/-/~ en el margen) y mini.git (comandos
-- base). vim-fugitive no necesita setup: sus comandos (:Git, :G…)
-- quedan activos solo por estar en runtimepath.
-- =========================================================
local ok_diff, diff = pcall(require, "mini.diff")
if ok_diff then
  diff.setup()
end

local ok_git, git = pcall(require, "mini.git")
if ok_git then
  git.setup()
end
