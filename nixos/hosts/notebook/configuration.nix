#===================================================================
# CONFIGURACIÓN NixOS — Notebook (ThinkPad)
#===================================================================
# Optimizado para portátil Lenovo ThinkPad:
#   - Gestión térmica y de batería.
#   - Servicios de ahorro de energía.
#   - Sin virtualización (vm.libvirtd = false).
#   - Sin opensnitch (services.opensnitch.enable = false).
#===================================================================
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../shared/default.nix
  ];

  #-----------------------------------------------------------------
  # IDENTIDAD
  #-----------------------------------------------------------------
  networking.hostName = "notebook";

  #-----------------------------------------------------------------
  # TECLADO
  #-----------------------------------------------------------------
  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };

  #-----------------------------------------------------------------
  # OPTIMIZACIONES ThinkPad
  #-----------------------------------------------------------------
  # acpi_call: Permite controlar la carga de la batería.
  boot.kernelModules = [ "acpi_call" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

  # thermald: Termal daemon de Intel para evitar throttling.
  services.thermald.enable = true;

  # throttled: Gestión de límites de energía de la CPU (undo TDP).
  # FRENAR: En ThinkPads viejos evita que la CPU se ahogue.
  services.throttled.enable = true;

  # fwupd: Actualización de firmware Lenovo/Linux desde el sistema.
  services.fwupd.enable = true;

  # power-profiles-daemon: Perfiles de energía (rendimiento, balanceado, ahorro).
  services.power-profiles-daemon.enable = true;

  #-----------------------------------------------------------------
  # BATERÍA (ThinkPad)
  #-----------------------------------------------------------------
  # charge_control_start/end_threshold: Limita la carga al 75-80%
  # para prolongar la vida útil de la batería Li-ion.
  # NOTA: Solamente BAT0 existe en este modelo (batería interna).
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT0/charge_control_start_threshold - - - - 75"
    "w /sys/class/power_supply/BAT0/charge_control_end_threshold   - - - - 80"
  ];

  #-----------------------------------------------------------------
  # PAQUETES DE SISTEMA (Portátil)
  #-----------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    brightnessctl # Control de brillo desde terminal.
    powertop      # Diagnóstico y optimización de energía Intel.
  ];

  #-----------------------------------------------------------------
  # SYNCTHING
  #-----------------------------------------------------------------
  # dataDir apunta al escritorio (disco interno siempre montado).
  services.syncthing.dataDir = "/home/necro/Desktop/";
  programs.nm-applet.enable = true;

  #-----------------------------------------------------------------
  # KERNEL
  #-----------------------------------------------------------------
  # Usamos el kernel por defecto de nixpkgs (zen optimizado).
  boot.kernelPackages = pkgs.linuxPackages_zen;

  #-----------------------------------------------------------------
  # MÓDULOS DESACTIVADOS PARA ESTE HOST
  #-----------------------------------------------------------------
  vm.libvirtd = false;               # Sin virtualización en portátil.
  services.opensnitch.enable = false; # Sin firewall interactivo.

  #-----------------------------------------------------------------
  # STATE VERSION (NO CAMBIAR)
  #-----------------------------------------------------------------
  system.stateVersion = "25.05";
}
