{ pkgs-unstable, ... }:
{
  services.spotifyd = {
    enable = true;
    package = pkgs-unstable.spotifyd;

    # En lugar de 'config', usamos 'settings' con atributos Nix.
    settings = {
      global = {
        device_name = "nixS";
        device_type = "computer";
        use_mpris = true;
        dbus_type = "session";
        disable_discovery = false;
        # IMPORTANTE: "pipewire" no es un backend válido para spotifyd.
        # Se debe usar "pulseaudio", que funciona perfectamente con PipeWire.
        backend = "pulseaudio";
        bitrate = 320;
        initial_volume = 70;
        volume_normalisation = true;
        max_cache_size = 1000000000;
      };
    };
  };
}
