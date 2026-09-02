#===================================================================
# OBS — Captura de pantalla + cámara virtual (stack Zoom)
#===================================================================
# Paqueteínía local del usuario (solo en equipos donde se habilite).
# Apoya el stack de compartición de pantalla de Zoom sobre niri:
#   OBS (captura con portal) → Virtual Camera → Zoom "2nd camera".
#
# DESACTIVADO POR DEFECTO: solo se instala donde programs.obs.enable
# = true (ver home-manager/hosts/desktop/default.nix).
#===================================================================
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.obs;
in {
  options.programs.obs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Instala OBS Studio (captura + cámara virtual) para el usuario.
        Solo en equipos que compartan pantalla por Zoom.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.obs-studio ];
  };
}