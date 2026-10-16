{ lib, config, pkgs-unstable, hostname, ... }:

let
  cfg = config.miConfig.spotify;
in
{
  options.miConfig.spotify = {
    deviceName = lib.mkOption {
      type = lib.types.str;
      default = hostname;
      example = "Spotify de necro";
      description = ''
        Nombre del dispositivo que spotifyd anuncia en la red.
        Aparece en la app de Spotify como un dispositivo "Spotify Connect".
        Por defecto usa el hostname del equipo.
      '';
    };
  };

  config.services.spotifyd = {
    enable = true;
    package = pkgs-unstable.spotifyd;

    settings.global = {
      device_name = cfg.deviceName;
      device_type = "computer";
      use_mpris = true;
      dbus_type = "session";
      disable_discovery = false;
      backend = "pulseaudio";
      bitrate = 320;
      initial_volume = 70;
      volume_normalisation = true;
      max_cache_size = 1000000000;
    };
  };
}
