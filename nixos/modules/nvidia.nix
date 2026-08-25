#===================================================================
# NVIDIA — Driver Propietario (Serie 570)
#===================================================================
# Configuración completa para GPU NVIDIA Kepler/Maxwell/+
# con soporte Wayland (modesetting, DRM, VA-API).
#
# GPU REAL del host desktop: GeForce GTX 970 (GM204, Maxwell).
#   Verificado con: lspci → "NVIDIA Corporation GM204 [GeForce GTX 970]".
#   El driver 570.195.03 renderiza correctamente con esta GPU
#   (evidencia: noctalia reporta "OpenGL ES 3.2 NVIDIA 570.195.03",
#   renderer "GeForce GTX 970", en los boots donde el greeter funciona).
#
# DRIVER PINNEADO: 570.195.03
# MOTIVO: La GPU requiere una versión específica del driver. Algunos
# kernels modernos rompen la compatibilidad, por eso el kernel está
# pinneado a 6.18.13 vía nixpkgs-kernel (ver flake.nix).
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
#
# CAMBIOS 2026-08-24 (pantalla negra intermitente del greeter — ver
# nixos/hosts/desktop/ISSUES.md para el diagnóstico completo):
#   1. ELIMINADO boot.initrd.kernelModules con nvidia*: cargar el driver
#      en el initrd con boot.initrd.systemd.enable = true es una causa
#      conocida de cuelgues/pantalla negra al arrancar, y además es
#      redundante: systemd-modules-load inserta los módulos igual a los
#      ~2s del boot (evidencia: journalctl 2026-08-21 16:37:38 "Inserted
#      module 'nvidia'"). El initrd queda solo con simpledrm (framebuffer
#      temprano), que es lo que se ve en el log antes de que udev cargue
#      nvidia.
#   2. ELIMINADO el kernel param "nvidia.NVreg_EnableGpuFirmware=0": esa
#      opción solo aplica a GPUs con GSP firmware (Turing+). La GTX 970
#      es Maxwell y no tiene GSP, así que el parámetro era código muerto;
#      se quita para no arrastrar config sin efecto.
#===================================================================
{ config, pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Los módulos nvidia NO se cargan en el initrd (ver ISSUES.md del host
  # desktop, cambio 2026-08-24). Con boot.initrd.systemd.enable = true la
  # carga temprana del driver es un riesgo de cuelgue sin beneficio: el
  # framebuffer temprano usa simpledrm y udev/systemd-modules-load inserta
  # nvidia a los ~2s del boot. Los módulos del initrd quedan a cargo del
  # hardware-configuration.nix (generado).
  # uvm no necesita initrd: se carga post-boot.
  boot.kernelModules = [ "nvidia_uvm" ];
  boot.kernelParams = [
    "nvidia_drm.fbdev=1"
    "nvidia_drm.modeset=1"
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
