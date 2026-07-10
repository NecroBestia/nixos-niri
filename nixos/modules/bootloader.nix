#===================================================================
# BOOTLOADER — GRUB EFI + Dual-Boot Windows
#===================================================================
# Configura GRUB como gestor de arranque con:
#   - EFI: Arranque UEFI nativo (canTouchEfiVariables).
#   - osProber: Detecta automáticamente Windows y lo añade al menú
#     de GRUB (esencial para dual-boot).
#   - ntfs3: Soporte para leer/escribir particiones NTFS (Windows)
#     a través del driver ntfs3 nativo del kernel (más rápido que ntfs-3g).
#
# plymouth.enable = false: Desactiva la pantalla de carga animada
# (evita parpadeos con NVIDIA + initrd systemd).
#
# initrd.systemd.enable = true: Usa systemd en el initrd
# (mejor manejo de montajes y dependencias en arranque temprano).
#===================================================================
{ ... }: {
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;  # Detecta Windows automáticamente.
    };
  };

  boot.supportedFilesystems = [ "ntfs3" ];
  boot.plymouth.enable = false;

  boot.initrd.systemd.enable = true;
}
