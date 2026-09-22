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
{ config, lib, ... }:

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
    programs = {
      swaylock.enable = true;
    };

    # Archivos individuales en vez de xdg.configFile."niri/" (directorio completo).
    # Con directorio, HM choca contra ~/.config/niri existente en checkLinkTargets
    # incluso con force = true. Archivos individuales evitan la colisión.
    home.file = {
      ".config/niri/binds.kdl"    = { source = ../config/niri/binds.kdl;    force = true; };
      ".config/niri/config.kdl"   = { source = ../config/niri/config.kdl;   force = true; };
      ".config/niri/input.kdl"    = { source = ../config/niri/input.kdl;    force = true; };
      ".config/niri/layout.kdl"   = { source = ../config/niri/layout.kdl;   force = true; };
      ".config/niri/noctalia.kdl" = { source = ../config/niri/noctalia.kdl; force = true; };
      ".config/niri/outputs.kdl"  = { source = ../config/niri/outputs.kdl;  force = true; };
      ".config/niri/rules.kdl"    = { source = ../config/niri/rules.kdl;    force = true; };
      ".config/niri/startup.kdl"  = { source = ../config/niri/startup.kdl;  force = true; };
    };

    # Noctalia modifica estos archivos en caliente (noctalia.kdl, config.kdl).
    # HM los despliega como symlinks read-only; el activation block asegura
    # que sean archivos escribibles después de cada regeneración.
    home.activation.ensureWritableNiriConfig = config.lib.dag.entryAfter ["linkGeneration"] ''
      niri_dir="${config.home.homeDirectory}/.config/niri"
      if [ -d "$niri_dir" ]; then
        find "$niri_dir" -type l -name "*.kdl" -exec sh -c '
          target=$(readlink -f "$1" 2>/dev/null || true)
          if [ -n "$target" ] && [ -f "$target" ]; then
            rm -f "$1" && cp "$target" "$1" && chmod u+w "$1"
          fi
        ' _ {} \;
      fi
    '';

    services = {
      swayidle = {
        enable = true;
        systemdTargets = [ "graphical-session.target" ];
        # ÚNICO gestor de idle del sistema: Noctalia no define
        # [idle.behavior.*] en config.toml / configNotebook.toml (con la tabla
        # vacía sus comportamientos builtin quedan deshabilitados). Antes
        # convivían los dos y se pisaban: swayidle bloqueaba a los 600 s y
        # Noctalia suspendía a los 900 s.
        #   -w                    espera al comando (necesario para
        #                         before-sleep y lock).
        #   power-off/on-monitors acciones DPMS de niri.
        extraArgs = [
          "-w"
          "timeout" "600" "noctalia msg session lock"
          "timeout" "660" "niri msg action power-off-monitors"
          "resume" "niri msg action power-on-monitors"
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
