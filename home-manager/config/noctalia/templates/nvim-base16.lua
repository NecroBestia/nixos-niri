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
    base08 = '{{colors.error.default.hex | set_hue 0 | set_lightness 55 | saturate 40}}',
    base09 = '{{colors.tertiary.default.hex | set_hue 25 | saturate 30 | set_lightness 60}}',
    base0A = '{{colors.secondary.default.hex | set_hue 50 | saturate 30 | set_lightness 65}}',
    base0B = '{{colors.primary.default.hex | set_hue 120 | saturate 30 | set_lightness 60}}',
    base0C = '{{colors.tertiary_fixed_dim.default.hex | set_hue 180 | saturate 30 | set_lightness 65}}',
    base0D = '{{colors.primary_fixed_dim.default.hex | set_hue 220 | saturate 30 | set_lightness 65}}',
    base0E = '{{colors.secondary_fixed_dim.default.hex | set_hue 280 | saturate 30 | set_lightness 65}}',
    base0F = '{{colors.error_container.default.hex | set_lightness 25 | saturate 20}}',
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
