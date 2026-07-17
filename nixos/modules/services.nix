#===================================================================
# SERVICIOS — SSH, Syncthing, Flatpak, Portales XDG
#===================================================================
# SSH: Servidor OpenSSH con autenticación solo por clave.
# Syncthing: Sincronización P2P de archivos entre dispositivos.
# Flatpak: Gestor de paquetes universal (Sandbox).
# Portales XDG: Integración entre apps Flatpak/nativas y Wayland.
#
# PORTALES XDG:
#   - common.default = [ "gnome" ]: GNOME es el backend por defecto
#     para todos los portales. GTK está disponible pero no default,
#     para evitar que interfiera con ScreenCast en Niri.
#   - niri.default = [ "gnome" ]: Misma razón para Niri.
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
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config = {
        common.default = [ "gnome" ];
        niri = {
          default = lib.mkForce [ "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        };
      };
    };
  };
}
