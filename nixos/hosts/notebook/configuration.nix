{ config, pkgs, ... }:

{
  imports = [
    # El archivo que generaste con nixos-generate-config
    ./hardware-configuration.nix

    # AQUÍ VAN TUS MÓDULOS (Descomenta y ajusta las rutas de tu Flake)
    # ../../modules/niri.nix
    # ../../modules/services.nix
    # ../../modules/pipewire.nix
  ];

  networking.hostName = "notebook";

  # ==========================================
  # OPTIMIZACIONES PARA THINKPAD T480
  # ==========================================

  # 1. Gráficos Integrados Intel (UHD 620)
  # Aceleración por hardware para video y Wayland fluido
  hardware.graphics = { # Nota: Si usas NixOS 23.11 o inferior, cambia "graphics" por "opengl"
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Driver VA-API moderno para procesadores Intel
      vaapiIntel         # Driver VA-API antiguo (por compatibilidad)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  # "modesetting" es el driver más estable y recomendado para Intel actual
  services.xserver.videoDrivers = [ "modesetting" ];

  # 2. Gestión de Energía (Power Bridge - Doble Batería)
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # Desactiva el Turbo Boost en batería para evitar que se drene rápido y se caliente
      CPU_BOOST_ON_BAT = 0;

      # Umbrales de carga para BAT0 (Interna) y BAT1 (Extraíble)
      # Esto evita que se carguen al 100% todo el tiempo, duplicando su vida útil
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;
    };
  };

  # 3. Periféricos: TrackPoint, Touchpad y Teclas Especiales
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
    };
  };
  # Vital para que funcionen las teclas de FN para subir/bajar brillo
  programs.light.enable = true;

  # 4. Actualizaciones de BIOS/Firmware
  # Lenovo da soporte oficial a Linux. Con esto podrás actualizar la BIOS desde la terminal
  services.fwupd.enable = true;

  # 5. Lector de Huellas (Descomenta si tu T480 tiene el sensor cuadrado a la derecha del touchpad)
  # services.fprintd.enable = true;

  # ==========================================
  # CONFIGURACIÓN DE USUARIO
  # ==========================================

  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    # "video" es importante para controlar el brillo
    # "input" es importante para atajos de teclado a bajo nivel
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
  };

  # Cambia esto a la versión de NixOS que estés usando en tu Flake (ej. "24.05" o "unstable")
  system.stateVersion = "24.05"; 
}