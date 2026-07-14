#===================================================================
# NIRI — Compositor Wayland (User-Level)
#===================================================================
# Este módulo configura el entorno de usuario para Niri:
#   - Copia los archivos de configuración (config/niri/) a ~/.config/niri/.
#   - Habilita servicios esenciales para el entorno Wayland.
#
# SERVICIOS:
#   - swayidle: Gestión de inactividad (bloqueo + suspensión).
#     * timeout 600s (10 min): Bloquea la pantalla vía Noctalia.
#     * timeout 1200s (20 min): Suspende el sistema.
#     * before-sleep: Bloquea antes de suspender.
#     * lock: Bloqueo manual.
#   - polkit-gnome: Diálogo de autorización para apps que necesitan
#     permisos del sistema (ej: mount, format).
#   - gnome-keyring: Almacenamiento seguro de contraseñas y claves SSH.
#
# PROGRAMAS:
#   - swaylock: Pantalla de bloqueo compatible con Wayland.
#
# NOTIFICACIONES:
#   Gestionadas por Noctalia (notification.daemon = true en config.toml).
#   No se usa mako ni swaync explícitamente.
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

    programs = {
      swaylock.enable = true;
    };

    services = {
      swayidle = {
        enable = true;
        systemdTargets = [ "graphical-session.target" ];
        extraArgs = [
          "-w"
          "timeout" "600" "noctalia msg session lock"
          "timeout" "1200" "loginctl suspend"
          "before-sleep" "noctalia msg session lock"
          "lock" "noctalia msg session lock"
        ];
      };

      polkit-gnome.enable = true;
      gnome-keyring.enable = true;
    };
  };
}
