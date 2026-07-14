{ pkgs, inputs, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    systemd.enable = true;

    settings = ../config/noctalia/config.toml;
  };

  home.file.".cache/noctalia-symlink-stub".text = ''
    # Stub — deleted after first wallpaper change creates the actual symlink
  '';
}
