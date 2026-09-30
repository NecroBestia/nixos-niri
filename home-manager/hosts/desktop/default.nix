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

  # Plugins de Noctalia fijados por Nix (instalación declarativa).
  # El módulo los despliega como fuente "local" de Noctalia (mayor precedencia);
  # la lista de plugins ACTIVOS vive en [plugins].enabled del TOML del flake.
  # Añadir/actualizar: ~/Projects/opencodePlans/noctalia-plugins-declarativos/README.md
  noctaliaPlugins = {
    enable = true;
    pins = {
      "nightwatch75/file-search" = {
        url = "https://github.com/noctalia-dev/community-plugins";
        rev = "a4645e83b0340fa9d259729231c94702272e4978";
        hash = "sha256-XPvrTzGeH/kBt4TLYWjVeD6czbya+WX9ZDTE4Lvru18=";
      };
      "blackbartblues/audio-switcher" = {
        url = "https://github.com/noctalia-dev/community-plugins";
        rev = "a4645e83b0340fa9d259729231c94702272e4978";
        hash = "sha256-2hV78KkbobxHafIY4jfW7xLrW1DU+w697lpOHgb/y18=";
      };
    };
  };

  home.packages = [ ];
}
