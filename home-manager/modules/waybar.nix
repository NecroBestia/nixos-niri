#===================================================================
# WAYBAR — Barra de Estado Wayland
#===================================================================
# Waybar es una barra de estado altamente configurable para
# compositores Wayland. Los archivos de configuración se definen
# por host:
#   - Desktop:  configDesktop.jsonc (módulos directos).
#   - Notebook: configNotebook.jsonc (grupos colapsables).
#
# Los archivos comunes (style.css, modules.jsonc) se enlazan aquí.
# La configuración principal (orden de módulos) se define en cada
# host (home-manager/hosts/<host>/default.nix).
#===================================================================
{ config, lib, ... }:

let
  cfg = config.programs.waybar;
in {
  config = lib.mkIf cfg.enable {
    xdg.configFile."waybar/style.css".source    = ../config/waybar/style.css;
    xdg.configFile."waybar/modules.jsonc".source = ../config/waybar/modules.jsonc;
  };
}
