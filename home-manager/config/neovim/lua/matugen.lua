 local M = {}

function M.setup()
  local ok, colorscheme = pcall(require, 'base16-colorscheme')
  if not ok then return end
  colorscheme.setup({
    base00 = '#121414',
    base01 = '#1e2020',
    base02 = '#292a2b',
    base03 = '#8b9294',
    base04 = '#c1c7ca',
    base05 = '#e3e2e3',
    base06 = '#e3e2e3',
    base07 = '#e3e2e3',
    base08 = '#ffb4ab',
    base09 = '#d4bfde',
    base0A = '#bcc8cd',
    base0B = '#abccd7',
    base0C = '#d4bfde',
    base0D = '#abccd7',
    base0E = '#bcc8cd',
    base0F = '#93000a',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#e3e2e3',          bg = '#121414' })
  hi('TelescopeBorder',         { fg = '#8b9294',             bg = '#121414' })
  hi('TelescopePromptNormal',   { fg = '#e3e2e3',          bg = '#121414' })
  hi('TelescopePromptBorder',   { fg = '#8b9294',             bg = '#121414' })
  hi('TelescopePromptPrefix',   { fg = '#abccd7',             bg = '#121414' })
  hi('TelescopePromptCounter',  { fg = '#c1c7ca',  bg = '#121414' })
  hi('TelescopePromptTitle',    { fg = '#121414',             bg = '#abccd7' })
  hi('TelescopePreviewTitle',   { fg = '#121414',             bg = '#bcc8cd' })
  hi('TelescopeResultsTitle',   { fg = '#121414',             bg = '#d4bfde' })
  hi('TelescopeSelection',      { fg = '#e3e2e3',          bg = '#292a2b' })
  hi('TelescopeSelectionCaret', { fg = '#abccd7',             bg = '#292a2b' })
  hi('TelescopeMatching',       { fg = '#abccd7',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
