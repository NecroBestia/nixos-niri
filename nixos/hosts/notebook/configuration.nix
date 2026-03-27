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

  # --- Optimización específica para ThinkPad ---
  boot.kernelModules = ["acpi_call"];
  boot.extraModulePackages = with config.boot.kernelPackages; [acpi_call];  
  #Configuraciones de temperatura 
  services.thermald.enable=true; 
  services.throttled.enable=true; 
  # fwupd permite actualizar el firmware de Lenovo directamente desde Linux
  services.fwupd.enable = true; 
  # Configuraciones de bateria 
  services.power-profiles-daemon.enable = true;
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT0/charge_control_start_threshold - - - - 75"
    "w /sys/class/power_supply/BAT0/charge_control_end_threshold   - - - - 80"
    "w /sys/class/power_supply/BAT1/charge_control_start_threshold - - - - 75"
    "w /sys/class/power_supply/BAT1/charge_control_end_threshold   - - - - 80"
  ]; 
  # --- Usuario Principal ---
  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" "input" "storage"];
  };
  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
  ]; 
  programs.nm-applet.enable = true; 
  # Permitir paquetes privativos (necesario para algunos drivers de red o codecs)
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # No cambies este valor a menos que sepas exactamente lo que haces.
  system.stateVersion = "25.05"; 
}
