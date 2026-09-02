#===================================================================
# ZOOM (NIXOS) — Cámara virtual para compartir pantalla en Zoom
#===================================================================
# Stack de compartición de pantalla de Zoom sobre niri. Fuera del
# alcance de home-manager (requiere módulos de kernel → nivel sistema).
#
# MOTIVO del módulo: niri solo ofrece BGRx+DMA-BUF en el screencast y
# el cliente de Zoom no acepta ese formato ("no more input formats") —
# https://github.com/niri-wm/niri/issues/4301 (sin fix aguas arriba).
# Workaround funcional: capturar con OBS (portal de niri) y publicar
# como cámara virtual; en Zoom: Share Screen → Advanced → "2nd camera".
#
# DESACTIVADO POR DEFECTO: solo el desktop lo habilita. En equipos que
# no usen Zoom+OBS, no se compila ni se carga el módulo de kernel.
#===================================================================
{ config, lib, ... }:

let
  cfg = config.programs.zoom.virtualCamera;
in {
  options.programs.zoom.virtualCamera = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Crea el dispositivo de cámara virtual v4l2loopback
        (/dev/video10) para el stack OBS → Zoom ("Share content from
        2nd camera").
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelModules = [ "v4l2loopback" ];
      # Compilado contra el kernel pinneado del equipo (desktop: zen).
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      # video_nr=10: /dev/video10 (no choca con cámaras reales).
      # exclusive_caps=1: requerido por la Virtual Camera de OBS.
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera" video_nr=10
      '';
    };
  };
}