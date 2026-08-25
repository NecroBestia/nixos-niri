#===================================================================
# ZOOM (FLATPAK) — Config mínima para el cliente Flatpak
#===================================================================
# El cliente de Zoom se usa SOLO vía Flatpak (us.zoom.Zoom) porque el
# paquete nix (zoom-us, sandbox FHS) no puede usar el GPU NVIDIA para
# EGL-wayland dentro del bwrap y no comparte pantalla.
#   Instalar una vez:
#     flatpak install -y flathub us.zoom.Zoom
#
# ESTE MÓDULO SOLO DESPLIEGA CONFIG:
#   - zoomus.conf para el XDG_CONFIG_HOME del Flatpak
#     (enableWaylandShare=true + xwayland=false → share nativo Wayland).
#   - Window rules de niri (~/.config/niri/zoom.kdl).
# NO instala ningún paquete; los handlers zoommtg:// y el desktop entry
# los registra el propio Flatpak al instalarse.
#===================================================================
{ config, lib, ... }:

let
  cfg = config.programs.zoom;

  zoomConf = ''
    [General]
    enableWaylandShare=${lib.boolToString cfg.enableWaylandShare}
    xwayland=${lib.boolToString cfg.useXwayland}
  '';
in {
  options.programs.zoom = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Despliega la configuración del cliente Flatpak de Zoom.";
    };

    enableWaylandShare = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Compartir pantalla vía PipeWire en modo Wayland (zoomus.conf).";
    };

    useXwayland = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Fuerza Zoom a XWayland (fallback).";
    };

    niriWindowRules = lib.mkOption {
      type = lib.types.lines;
      default = ''
        // Zoom: menús/popups flotantes para que no rompan el tiling.
        window-rule {
            match app-id="Zoom Workplace" title=".*menu.*"
            open-floating true
            min-width 250
            open-focused true
        }
      '';
      description = "Window rules de niri para Zoom (desplegadas en ~/.config/niri/zoom.kdl).";
    };
  };

  config = lib.mkIf cfg.enable {
    # XDG_CONFIG_HOME propio del Flatpak (us.zoom.Zoom).
    home.file.".var/app/us.zoom.Zoom/.config/zoomus.conf".text = zoomConf;

    # Reglas de ventana incluidas desde config.kdl ("include zoom.kdl").
    home.file.".config/niri/zoom.kdl".text = cfg.niriWindowRules;
  };
}