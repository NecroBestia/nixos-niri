#===================================================================
# CONFIGURACIÓN NixOS — Notebook (ThinkPad)
#===================================================================
# Optimizado para portátil Lenovo ThinkPad:
#   - Gestión térmica y de batería.
#   - Servicios de ahorro de energía.
#   - Sin virtualización (vm.libvirtd = false).
#   - Sin opensnitch (services.opensnitch.enable = false).
#===================================================================
{ config, pkgs, lib, inputs, ... }:

let
  #-----------------------------------------------------------------
  # Kernel pinneado (nixpkgs-kernel)
  #-----------------------------------------------------------------
  # MOTIVO: el kernel zen 7.1.2 de nixpkgs 26.05 provocaba un oops del
  # kernel (execmem_free/load_module) en el primer hotplug USB, dejando
  # al GameSir-K1 sin permisos en /dev/input. Se usa el mismo kernel
  # pinneado (6.18.13 zen, rev d756e13) que el desktop.
  pkgs-kernel = import inputs.nixpkgs-kernel {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
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
  # TABLETA GRÁFICA
  #-----------------------------------------------------------------
  # Paquete stock de nixpkgs (igual que en desktop).
  # NOTA: el override a OTD master (pkgs/opentabletdriver-master.nix)
  # era por el kernel 7.1; si la tablet fallara con 6.18.13, volver a él.
  hardware.opentabletdriver.enable = true;

  #-----------------------------------------------------------------
  # SYNCTHING
  #-----------------------------------------------------------------
  # dataDir apunta al escritorio (disco interno siempre montado).
  services.syncthing.dataDir = "/home/necro/Desktop/";
  programs.nm-applet.enable = true;

  #-----------------------------------------------------------------
  # KERNEL
  #-----------------------------------------------------------------
  # Kernel pinneado de nixpkgs-kernel (6.18.13 zen), igual que el desktop.
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs-kernel.linuxPackages_zen.kernel;

  # Fallback: si un worker de udev vuelve a morir procesando el GameSir,
  # esta regla asegura dueño/grupo/permisos correctos en sus nodos input.
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ATTRS{idVendor}=="3537", ATTRS{idProduct}=="1012", GROUP="input", MODE="0660"
  '';

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
