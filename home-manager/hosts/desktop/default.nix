#===================================================================
# HOME MANAGER — Desktop
#===================================================================
# Configuración específica del usuario para la PC de sobremesa.
# Hereda toda la configuración compartida de ../shared/default.nix.
#
# Cada host tiene su propio archivo Waybar:
#   - Desktop: configDesktop.jsonc (muestra módulos de audio
#     wireplumber#sink/source directamente, sin grupos).
#   - Notebook: configNotebook.jsonc (usa grupos colapsables).
#===================================================================
{ pkgs, pkgs-unstable, ... }: {
  imports = [
    ../../shared/default.nix
  ];

  home = {
    username = "necro";
    homeDirectory = "/home/necro";
    stateVersion = "26.05";
  };

  home.packages = [ ];

  # Configuración de Waybar específica del escritorio.
  xdg.configFile."waybar/config.jsonc".source = ../../config/waybar/configDesktop.jsonc;
}
