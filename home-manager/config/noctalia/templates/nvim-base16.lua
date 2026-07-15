local M = {}
function M.setup()
  require('base16-colorscheme').setup {
    base00 = '{{colors.surface.default.hex}}',
    base01 = '{{colors.surface_container.default.hex}}',
    base02 = '{{colors.surface_container_high.default.hex}}',
    base03 = '{{colors.outline.default.hex}}',
    base04 = '{{colors.on_surface_variant.default.hex}}',
    base05 = '{{colors.on_surface.default.hex}}',
    base06 = '{{colors.on_surface.default.hex}}',
    base07 = '{{colors.on_background.default.hex}}',
    base08 = '{{colors.error.default.hex | rotate_hue 0 | set_lightness 55 | saturate 30}}',
    base09 = '{{colors.tertiary.default.hex | rotate_hue 30 | set_lightness 60 | saturate 20}}',
    base0A = '{{colors.secondary.default.hex | rotate_hue 60 | set_lightness 65 | saturate 20}}',
    base0B = '{{colors.primary.default.hex | rotate_hue 120 | set_lightness 60 | saturate 20}}',
    base0C = '{{colors.tertiary_fixed_dim.default.hex | rotate_hue 180 | set_lightness 65 | saturate 20}}',
    base0D = '{{colors.primary_fixed_dim.default.hex | rotate_hue 220 | set_lightness 65 | saturate 20}}',
    base0E = '{{colors.secondary_fixed_dim.default.hex | rotate_hue 280 | set_lightness 65 | saturate 20}}',
    base0F = '{{colors.error_container.default.hex | rotate_hue 0 | set_lightness 25 | saturate 15}}',
  }
end

local signal = vim.uv.new_signal()
signal:start('sigusr1', vim.schedule_wrap(function()
  local config_dir = vim.fn.stdpath('config')
  local ok, mod = pcall(dofile, config_dir .. '/lua/noctalia.lua')
  if ok and mod and mod.setup then
    mod.setup()
  end
end))

return M
