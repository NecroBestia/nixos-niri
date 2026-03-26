{ config, lib, ... }:

let
  cfg = config.programs.waybar;
in
{
  config = lib.mkIf cfg.enable {


    # Archivos externos
    xdg.configFile."waybar/style.css".source = lib.mkForce ../config/waybar/style.css;
    xdg.configFile."waybar/modules.jsonc".source = lib.mkForce ../config/waybar/modules.jsonc;
  };
}