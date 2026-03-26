{ config, pkgs, ... }:

{
  imports =
    [ # Incluye los resultados del escaneo de hardware generado automáticamente.
      ./hardware-configuration.nix
      ../default.nix

    ];

  # --- Redes ---
  networking.hostName = "notebook";
  networking.networkmanager.enable = true;


  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };
  console.keyMap = "la-latin1";

  # --- Entorno Gráfico (GNOME por defecto, puedes cambiarlo a KDE/Plasma si prefieres) ---
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # --- Optimización específica para ThinkPad ---
  # TLP mejora drásticamente la duración de la batería en las ThinkPads
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;
    };
  };
  # fwupd permite actualizar el firmware de Lenovo directamente desde Linux
  services.fwupd.enable = true; 
  services.power-profiles-daemon.enable = false; 
  # --- Usuario Principal ---
  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" "input" "storage"];
  };

  # Permitir paquetes privativos (necesario para algunos drivers de red o codecs)
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # No cambies este valor a menos que sepas exactamente lo que haces.
  system.stateVersion = "25.05"; 
}
