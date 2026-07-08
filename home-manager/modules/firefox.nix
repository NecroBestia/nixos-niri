#===================================================================
# FIREFOX — Navegador
#===================================================================
# Firefox desde nixpkgs-unstable para tener la última versión
# estable con las características más recientes de Wayland y
# soporte de DRM (Widevine, Netflix, etc.).
#
# Nota: Si se necesita integración con tridactyl-native,
# descomentar el bloque anterior y ajustar package.
#===================================================================
{ pkgs, pkgs-unstable, ... }: {
  programs.firefox = {
    enable = true;
    package = pkgs-unstable.firefox;
  };
}
