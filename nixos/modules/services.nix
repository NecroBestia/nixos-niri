#===================================================================
# SERVICIOS — SSH, Syncthing, Flatpak, Portales XDG
#===================================================================
# SSH: Servidor OpenSSH con autenticación solo por clave.
# Syncthing: Sincronización P2P de archivos entre dispositivos.
# Flatpak: Gestor de paquetes universal (Sandbox).
# Portales XDG: Integración entre apps Flatpak/nativas y Wayland.
#
# PORTALES XDG:
#   - common.default = [ "gtk" "gnome" ]: Las apps Flatpak usan
#     los backends GTK y GNOME para diálogos de archivo, etc.
#   - niri.default = lib.mkForce [ "gtk" "gnome" ]: Fuerza estos
#     mismos backends para el compositor Niri (evita que el portal
#     predeterminado use KDE/WLROOTS si están disponibles).
#   - ScreenCast/Screenshot usa "gnome": Portal de captura de
#     pantalla compatible con Niri + GNOME.
#===================================================================
{ pkgs, lib, ... }: {
  services = {
    # SSH — Solo por clave (sin contraseña ni root).
    openssh = {
      enable = true;
      ports = [22];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Syncthing — Sincronización P2P.
    # systemService = true: Corre como servicio del sistema (arranca
    # antes del login del usuario). dataDir se define por host
    # (desktop → disco NTFS, notebook → ~/Desktop/).
    syncthing = {
      enable = true;
      user = "necro";
      configDir = "/home/necro/.dataSync";
      openDefaultPorts = true;
      systemService = true;
    };

    flatpak.enable = true;
  };

  # Portales XDG para Wayland + Flatpak.
  xdg = {
    autostart.enable = true;
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config = {
        common.default = [ "gtk" "gnome" ];
        niri = {
          default = lib.mkForce [ "gtk" "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        };
      };
    };
  };
}
