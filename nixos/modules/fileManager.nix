{ config, pkgs, lib, ... }:

let
  user = "necro";
in
{
  options.fileManager.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Nautilus + GVFS + UDisks2 + Polkit Agent";
  };

  config = lib.mkIf config.fileManager.enable {
    environment.systemPackages = with pkgs; [
      nautilus
      gvfs
      polkit_gnome
      udisks2

      # --- PAQUETES AÑADIDOS ---
      gnome-autoar       # Para gestionar archivos .zip, .tar, etc.
      gnome-desktop      # Para thumbnails de imágenes y metadata
      ffmpegthumbnailer  # Para thumbnails de videos
      poppler-utils      #Para thumbnails de PDFs
      # ------------------------
    ];

    services = {
      dbus.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
    };

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "${user}") {
          if (action.id.startsWith("org.freedesktop.udisks2.")) {
            return polkit.Result.YES;
          }
        }
      });
    '';

    environment.etc."udisks2/mount_options.conf".text = ''
      [defaults]
      mount_point = /mnt/%u
   '';

  };
}
