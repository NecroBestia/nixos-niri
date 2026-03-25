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
    xdg.configFile."niri/".source = lib.mkForce ../config/niri; 
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
      swayidle  = {
        enable = true;
        systemdTarget ="graphical-session.target"; 
        extraArgs = [ 
          "-w"
          "timeout 600 'swaylock -f'"
          "timeout 1200 'loginctl suspend'"
          "before-sleep 'swaylock -f'"
          "lock 'swaylock -f'"
        ];
        
        };  # Gestión de inactividad
      polkit-gnome.enable = true; # Polkit para apps gráficas
      gnome-keyring.enable = true; # Almacenamiento de redenciales
    };
  };
}
