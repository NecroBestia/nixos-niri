{ config, pkgs, lib, ... }:
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
      gnome-autoar       # Para gestionar archivos .zip, .tar, etc.
      gnome-desktop      # Para thumbnails de imágenes y metadata
      ffmpegthumbnailer  # Para thumbnails de videos
      poppler-utils      #Para thumbnails de PDFs
      ntfs3g 
      exfat
      xdg-user-dirs
      adwaita-icon-theme
      shared-mime-info
    ];

    services = {
      dbus.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
    };  

    services.udisks2.settings = {
      "mount_options.conf" = {
        defaults = {
          # Pasamos los parámetros como una lista limpia de strings
          ntfs_defaults = [ "uid=$UID" "gid=$GID" "rw" "user" "exec" "umask=0022" "nofail" "force" "allow_other" ];
          ntfs_drivers = [ "ntfs3" ];
        };
      };   
    };
  };
}
