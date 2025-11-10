{ config, pkgs, lib, ... }:

let
  cfg = config.programs.niri;
in
{
  # Declaración de la opción
  options.programs.niri = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Habilita Niri y su entorno Wayland";
    };
  };

  # Configuración condicional
  config = lib.mkIf cfg.enable {
    # Copiar archivos de configuración de Niri
    xdg.configFile."niri/config.kdl".source = lib.mkForce ../config/niri/config.kdl; 
    # Paquetes esenciales para Niri y Wayland
    home.packages = [ pkgs.gcr ];

    # Programas opcionales útiles en entorno Niri
    programs = {
      #alacritty.enable = true;
      fuzzel.enable   = true;
      swaylock.enable = true;
    };

    # Servicios de usuario relacionados
    services = {
      mako.enable      = true;  # Notificaciones
      swayidle.enable  = true;  # Gestión de inactividad
      polkit-gnome.enable = true; # Polkit para apps gráficas
      gnome-keyring.enable = true; # Almacenamiento de redenciales
    };
  };
}