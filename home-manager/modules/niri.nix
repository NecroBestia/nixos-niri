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

    # Reemplaza symlinks del nix store por archivos escribibles,
    # para que Noctalia pueda escribir noctalia.kdl y modificar config.kdl.
    home.activation.ensureWritableNiriConfig = config.lib.dag.entryAfter ["linkGeneration"] ''
      niri_dir="${config.home.homeDirectory}/.config/niri"
      if [ -h "$niri_dir" ]; then
        # Caso legacy: ~/.config/niri era symlink al directorio completo
        echo "niri: replacing store symlink with writable directory"
        store_path="$(readlink -f "$niri_dir")"
        rm -f "$niri_dir"
        cp -r "$store_path" "$niri_dir"
        chmod -R u+w "$niri_dir"
      elif [ -d "$niri_dir" ]; then
        # Caso actual: archivos individuales, reemplazar symlinks
        for f in "$niri_dir"/*.kdl; do
          if [ -f "$f" ] && [ ! -h "$f" ]; then continue; fi
          store_path="$(readlink -f "$f" 2>/dev/null)"
          if [ -n "$store_path" ] && [ -f "$store_path" ]; then
            cp "$store_path" "$f"
            chmod u+w "$f"
            echo "niri: replaced symlink $(basename "$f") with writable copy"
          fi
        done
      fi
    '';

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
