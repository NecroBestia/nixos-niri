{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.noctalia;
in {
  options.programs.noctalia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Noctalia v5 Wayland shell";
    };
  };

  config = lib.mkIf cfg.enable {
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

      settings = builtins.fromTOML (builtins.readFile ../config/noctalia/config.toml);
    };

    # Ensure the wallpaper symlink target directory exists
    home.file.".cache/noctalia-symlink-stub".text = ''
      # Stub — deleted after first wallpaper change creates the actual symlink
    '';
  };
}
