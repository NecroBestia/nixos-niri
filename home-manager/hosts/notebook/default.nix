#===================================================================
# HOME MANAGER — Notebook
#===================================================================
# Configuración específica del usuario para el ThinkPad.
# Hereda toda la configuración compartida de ../shared/default.nix.
#
# Waybar del notebook usa grupos colapsables para ahorrar espacio
# horizontal en la pantalla 1366x768.
#===================================================================
{ lib, pkgs, ... }: {
  imports = [
    ../../shared/default.nix
  ];

  home = {
    username = "necro";
    homeDirectory = "/home/necro";
    stateVersion = "26.05";
  };

  home.packages = with pkgs; [ ];

  # Configuración de Waybar específica del portátil (grupos colapsables).
  xdg.configFile."waybar/config.jsonc".source = ../../config/waybar/configNotebook.jsonc;

  # Wlogout: CSS compacto para pantalla 1366x768 (sobrescribe el compartido).
  home.file.".config/wlogout/style.css".source = lib.mkForce ../../config/wlogout/styleNotebook.css;
}
