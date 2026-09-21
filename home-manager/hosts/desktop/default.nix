#===================================================================
# HOME MANAGER — Desktop
#===================================================================
# Configuración específica del usuario para la PC de sobremesa.
# Hereda toda la configuración compartida de ../shared/default.nix.
#
# Waybar no se usa (Noctalia v5 reemplaza la barra).
# Los estilos waybar/style.css quedan como referencia.
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
}
