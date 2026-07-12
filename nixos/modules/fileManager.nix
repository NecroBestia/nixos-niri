#===================================================================
# FILE MANAGER — Nautilus + GVFS + UDisks2
#===================================================================
# Nautilus es el gestor de archivos gráfico de GNOME.
# GVFS proporciona montaje virtual (SMB, FTP, MTP, etc.).
# UDisks2 gestiona el montaje de discos extraíbles.
#
# El módulo es TOGGLEABLE via fileManager.enable.
#
# CONFIGURACIÓN UDISKS2:
#   - ntfs_defaults: Opciones por defecto al montar NTFS:
#     uid=$UID, gid=$GID → Propietario = usuario actual.
#     allow_other → Otros usuarios pueden acceder.
#     force → Monta aunque el sistema de archivos no esté limpio.
#   - ntfs_drivers: Prefiere el driver ntfs3 del kernel.
#===================================================================
{ config, pkgs, lib, ... }: {
  options.fileManager.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Nautilus + GVFS + UDisks2 + Polkit Agent";
  };

  config = lib.mkIf config.fileManager.enable {
    environment.systemPackages = with pkgs; [
      nautilus
      gvfs
      udisks2
      gnome-autoar           # Compresión/descompresión ZIP, TAR, etc.
      gnome-desktop          # Thumbnails de imágenes y metadatos.
      ffmpegthumbnailer      # Thumbnails de videos.
      poppler-utils          # Thumbnails de PDFs.
      ntfs3g                 # Driver NTFS userspace (respaldo).
      exfat                  # Soporte para discos exFAT.
      xdg-user-dirs          # Directorios estándar del usuario.
      adwaita-icon-theme     # Iconos base de GNOME.
      shared-mime-info       # Tipos MIME del sistema.
    ];

    services = {
      dbus.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
    };

    services.udisks2.settings = {
      "mount_options.conf" = {
        defaults = {
          ntfs_defaults = [
            "uid=$UID" "gid=$GID" "rw" "user" "exec"
            "umask=0022" "nofail" "force" "allow_other"
          ];
          ntfs_drivers = [ "ntfs3" ];
        };
      };
    };
  };
}
