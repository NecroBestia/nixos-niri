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

    profiles.default = {
      id = 0;
      isDefault = true;

      # about:config preferences para clipboard en Wayland.
      settings = {
        # Usar portal XDG para portapapeles (necesario en Wayland).
        "widget.use-xdg-desktop-portal" = 1;
        # Pegar con botón central del ratón.
        "middlemouse.paste" = false;
        # Desactivar la advertencia de cierre de múltiples pestañas.
        "browser.tabs.warnOnClose" = false;
      };
    };
  };

  # Forzar Firefox a Wayland nativo para que el clipboard funcione.
  # Sin esto corre en XWayland y el clipboard de Noctalia no puede transferir datos.
  home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
}
