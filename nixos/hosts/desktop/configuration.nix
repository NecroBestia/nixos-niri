#===================================================================
# CONFIGURACIÓN NixOS — Desktop (PC de Sobremesa)
#===================================================================
# GPU dedicada NVIDIA (serie 570).
# Discos NTFS para datos compartidos con Windows.
# Kernel pinneado para compatibilidad con driver NVIDIA antiguo.
#===================================================================
{ pkgs, inputs, ... }:

let
  #-----------------------------------------------------------------
  # Kernel pinneado (nixpkgs-kernel)
  #-----------------------------------------------------------------
  # MOTIVO: La GPU NVIDIA serie 570 requiere el kernel 6.18.13 para
  # que el driver propietario compilar correctamente. Usar un kernel
  # más nuevo rompe la compatibilidad.
  # Se importa de un nixpkgs específico (rev d756e13).
  pkgs-kernel = import inputs.nixpkgs-kernel {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  #-----------------------------------------------------------------
  # IMPORTS
  #-----------------------------------------------------------------
  #   1. hardware-configuration.nix  → Autogenerado (discos, CPU).
  #   2. ../shared/default.nix       → Módulos compartidos.
  #   3. nvidia.nix                  → GPU NVIDIA.
  #   4. steam.nix                   → Gaming.
  imports = [
    ./hardware-configuration.nix
    ../shared/default.nix
    ../../modules/nvidia.nix
    ../../modules/steam.nix
  ];

  #-----------------------------------------------------------------
  # IDENTIDAD
  #-----------------------------------------------------------------
  networking.hostName = "desktop";

  #-----------------------------------------------------------------
  # SERVICIOS
  #-----------------------------------------------------------------
  hardware.opentabletdriver.enable = true; # Driver para tabletas gráficas.

  #-----------------------------------------------------------------
  # MONTAJE NTFS (Discos Compartidos con Windows)
  #-----------------------------------------------------------------
  # Cada entrada monta una partición NTFS con:
  #   - uid/gid 1000 → Propietario necro.
  #   - umask 0022  → Permisos 755.
  #   - force       → Monta incluso si no está limpio (Windows híbrido).
  #   - nofail      → No bloquea el arranque si falta el disco.
  #   - x-systemd.automount → Montaje bajo demanda (sin esperar en boot).
  #-----------------------------------------------------------------
  fileSystems."/mnt/not_to_lose" = {
    device = "/dev/disk/by-uuid/18324F22324F046A";
    fsType = "ntfs3";
    options = [
      "rw" "uid=1000" "gid=100" "umask=0022"
      "nofail" "force"
      "x-gvfs-name=not_to_lose" "x-gvfs-show"
      "x-systemd.automount"
    ];
  };

  fileSystems."/mnt/neverToLose" = {
    device = "/dev/disk/by-uuid/3EFA7B8AFA7B3D69";
    fsType = "ntfs3";
    options = [
      "rw" "uid=1000" "gid=100" "umask=0022"
      "nofail" "force"
      "x-gvfs-name=neverToLose" "x-gvfs-show"
      "x-systemd.automount"
    ];
  };

  fileSystems."/mnt/juegos" = {
    device = "/dev/disk/by-uuid/9E207F36207F150D";
    fsType = "ntfs3";
    options = [
      "rw" "uid=1000" "gid=100" "umask=0022"
      "nofail" "force"
      "x-gvfs-name=juegos" "x-gvfs-show"
      "x-systemd.automount"
    ];
  };

  #-----------------------------------------------------------------
  # SYNCTHING — Sincronización de Archivos
  #-----------------------------------------------------------------
  # dataDir apunta al disco NTFS montado.
  # El systemService = true está definido en services.nix.
  # NOTA: Syncthing esperará a que el disco esté montado gracias
  # al x-systemd.automount definido arriba.
  services.syncthing = {
    dataDir = "/mnt/not_to_lose/SyncThing";
  };

  #-----------------------------------------------------------------
  # KERNEL
  #-----------------------------------------------------------------
  # Usamos el kernel pinneado de nixpkgs-kernel con linuxPackagesFor
  # para mantener compatibilidad con el driver NVIDIA 570.
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs-kernel.linuxPackages_zen.kernel;

  #-----------------------------------------------------------------
  # STATE VERSION (NO CAMBIAR)
  #-----------------------------------------------------------------
  # Define el comportamiento de opciones legacy. Al cambiar, NixOS
  # aplica la nueva configuración por defecto de esa versión.
  system.stateVersion = "25.05";
}
