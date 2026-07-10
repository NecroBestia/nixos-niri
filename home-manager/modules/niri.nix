#===================================================================
# NIRI — Compositor Wayland (User-Level)
#===================================================================
# Este módulo configura el entorno de usuario para Niri:
#   - Copia los archivos de configuración (config/niri/) a ~/.config/niri/.
#   - Habilita servicios esenciales para el entorno Wayland.
#
# SERVICIOS:
#   - mako: Notificaciones nativas de Wayland (reemplaza dunst/notify-send).
#   - swayidle: Gestión de inactividad (bloqueo + suspensión).
#     * timeout 600s (10 min): Bloquea la pantalla con swaylock.
#     * timeout 1200s (20 min): Suspende el sistema.
#     * before-sleep: Bloquea antes de suspender.
#     * lock: Bloqueo manual.
#   - polkit-gnome: Diálogo de autorización para apps que necesitan
#     permisos del sistema (ej: mount, format).
#   - gnome-keyring: Almacenamiento seguro de contraseñas y claves SSH.
#
# PROGRAMAS:
#   - fuzzel: Lanzador de aplicaciones (similar a rofi/dmenu).
#   - swaylock: Pantalla de bloqueo compatible con Wayland.
#   - gcr: Paquete base de GNOME Crypto (necesario para gnome-keyring).
#===================================================================
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.niri;
in {
  options.programs.niri = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Habilita Niri y su entorno Wayland";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."niri/".source = ../config/niri;

    home.packages = [ pkgs.gcr ];

    programs = {
      fuzzel.enable   = true;
      swaylock.enable = true;
    };

    services = {
      mako.enable = true;

      swayidle = {
        enable = true;
        systemdTargets = [ "graphical-session.target" ];
        extraArgs = [
          "-w"
          "timeout" "600" "swaylock -f"
          "timeout" "1200" "loginctl suspend"
          "before-sleep" "swaylock -f"
          "lock" "swaylock -f"
        ];
      };

      polkit-gnome.enable = true;
      gnome-keyring.enable = true;
    };
  };
}
