{ config, lib, pkgs, ... }:

{
  options.stylix = {
    enable = lib.mkEnableOption "Stylix theming";
  };

  config.stylix = {
    enable = true;
    autoEnable = false;
    polarity = "dark";
    image = "/home/necro/.cache/current-stylix-wallpaper";

    base16Scheme = {
      slug = "catppuccin-mocha";
      name = "Catppuccin Mocha";
      author = "catppuccin";
      variant = "dark";
      palette = {
        base00 = "1e1e2e";
        base01 = "181825";
        base02 = "313244";
        base03 = "45475a";
        base04 = "585b70";
        base05 = "cdd6f4";
        base06 = "f5f5f5";
        base07 = "ffffff";
        base08 = "f38ba8";
        base09 = "fab387";
        base0A = "f9e2af";
        base0B = "a6e3a1";
        base0C = "94e2d5";
        base0D = "89b4fa";
        base0E = "cba6f7";
        base0F = "f2cdcd";
      };
    };
  };
}
