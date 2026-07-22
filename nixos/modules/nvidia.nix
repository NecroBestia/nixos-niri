#===================================================================
# NVIDIA — Driver Propietario (Serie 570)
#===================================================================
# Configuración completa para GPU NVIDIA Kepler/Maxwell/+
# con soporte Wayland (modesetting, DRM, VA-API).
#
# DRIVER PINNEADO: 570.195.03
# MOTIVO: La GPU de este sistema (serie 570) requiere una versión
# específica del driver. Algunos kernels modernos rompen la
# compatibilidad, por eso el kernel está pinneado (ver flake.nix).
#
# CONFIGURACIÓN CLAVE:
#   - modesetting.enable = true: Habilita KMS (Kernel Mode Setting)
#     para una integración limpia con Wayland.
#   - open = false: Usa el driver propietario (no el open-source
#     nvidia-open, que solo funciona en GPUs Turing+).
#   - fbdev=1 + modeset=1: Parámetros de DRM necesarios para
#     que Wayland funcione correctamente con NVIDIA.
#   - NVreg_PreserveVideoMemoryAllocations: Preserva la memoria
#     de video entre suspensiones/reanudaciones (evita crashes).
#   - powerManagement.enable: Permite que NVIDIA ahorre energía
#     cuando no hay cargas gráficas.
#   - nvidia-vaapi-driver: Aceleración de video por hardware
#     (VA-API) sobre NVIDIA (útil en Firefox, Chrome, etc.).
#===================================================================
{ config, pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
  boot.kernelModules = [ "nvidia_uvm" ];   # uvm no necesita initrd: se carga post-boot.
  boot.kernelParams = [
    "nvidia_drm.fbdev=1"
    "nvidia_drm.modeset=1"
    "nvidia.NVreg_EnableGpuFirmware=0"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    "pcie_aspm=off"
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "570.195.03";
      sha256_64bit = "sha256-1H3oHZpRNJamCtyc+nL+nhYsZfJyL7lgxPUxvXrF3B4=";
      sha256_aarch64 = pkgs.lib.fakeSha256;
      openSha256 = pkgs.lib.fakeSha256;
      settingsSha256 = "sha256-mjKkMEPV6W69PO8jKAKxAS861B82CtCpwVTeNr5CqUY=";
      persistencedSha256 = "sha256-h8pY3pY++J6BIsS2I9SInT6S3yP6X6U72XUeHnIe97o=";
    };
  };

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };
}
