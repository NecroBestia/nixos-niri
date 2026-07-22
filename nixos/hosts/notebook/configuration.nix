#===================================================================
# CONFIGURACIÓN NixOS — Notebook (ThinkPad)
#===================================================================
# Optimizado para portátil Lenovo ThinkPad:
#   - Gestión térmica y de batería.
#   - Servicios de ahorro de energía.
#   - Sin virtualización (vm.libvirtd = false).
#   - Sin opensnitch (services.opensnitch.enable = false).
#===================================================================
{ config, pkgs, lib, ... }:

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

  # thermald: Termal daemon de Intel para evitar throttling.
  services.thermald.enable = true;

  # FRENAR: En ThinkPads viejos evita que la CPU se ahogue.

  # fwupd: Actualización de firmware Lenovo/Linux desde el sistema.
  services.fwupd.enable = true;

  # power-profiles-daemon: Perfiles de energía (rendimiento, balanceado, ahorro).
  services.power-profiles-daemon.enable = true;

  # upower: Backend de batería para Noctalia y otros entornos Wayland.
  services.upower.enable = true;

  #-----------------------------------------------------------------
  # BATERÍA (ThinkPad)
  #-----------------------------------------------------------------
  # charge_control_start/end_threshold: Limita la carga al 75-80%
  # para prolongar la vida útil de la batería Li-ion.
  # NOTA: BAT1 es la batería interna en este modelo.
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT1/charge_control_start_threshold - - - - 75"
    "w /sys/class/power_supply/BAT1/charge_control_end_threshold   - - - - 80"
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
  programs.containers.enable = false; # Sin contenedores (Podman) en portátil (ahorra recursos del sistema).
  vm.libvirtd = false;               # Sin virtualización en portátil.
  services.opensnitch.enable = false; # Sin firewall interactivo.

  #-----------------------------------------------------------------
  # OPTIMIZACIONES POST-LOGIN
  #-----------------------------------------------------------------
  # Los portales XDG y servicios innecesarios no arrancan al login
  # para reducir el delay post-login (~6.5s en ThinkPad).
  # Se activan bajo demanda vía D-Bus cuando alguna app los necesita.
  systemd.user.services.xdg-desktop-portal.wantedBy = lib.mkForce [];
  systemd.user.services.xdg-desktop-portal-gnome.wantedBy = lib.mkForce [];
  systemd.user.services.xdg-desktop-portal-gtk.wantedBy = lib.mkForce [];
  systemd.user.services.gvfs-gphoto2-volume-monitor.wantedBy = lib.mkForce [];
  systemd.user.services.gvfs-afc-volume-monitor.wantedBy = lib.mkForce [];
  systemd.user.services.gvfs-goa-volume-monitor.wantedBy = lib.mkForce [];
  systemd.user.services.obex.wantedBy = lib.mkForce [];

  #-----------------------------------------------------------------
  # STATE VERSION (NO CAMBIAR)
  #-----------------------------------------------------------------
  system.stateVersion = "25.05";
}
