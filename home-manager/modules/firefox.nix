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

        # Zoom SSO: permitir que los deep links zoommtg:// etc. se
        # abran directo en el cliente (sin diálogo de Firefox).
        # Sin esto el clic en "Launch Zoom" post-Google-OAuth no hace nada.
        "network.protocol-handler.external.zoommtg" = true;
        "network.protocol-handler.warn-external.zoommtg" = false;
        "network.protocol-handler.external.zoomus" = true;
        "network.protocol-handler.warn-external.zoomus" = false;
        "network.protocol-handler.external.tel" = true;
        "network.protocol-handler.warn-external.tel" = false;
        "network.protocol-handler.external.callto" = true;
        "network.protocol-handler.warn-external.callto" = false;
        "network.protocol-handler.external.zoomphonecall" = true;
        "network.protocol-handler.warn-external.zoomphonecall" = false;
        "network.protocol-handler.external.zoomphonesms" = true;
        "network.protocol-handler.warn-external.zoomphonesms" = false;
        "network.protocol-handler.external.zoomcontactcentercall" = true;
        "network.protocol-handler.warn-external.zoomcontactcentercall" = false;
      };
    };
  };

  # Forzar Firefox a Wayland nativo para que el clipboard funcione.
  # Sin esto corre en XWayland y el clipboard de Noctalia no puede transferir datos.
  home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
}
