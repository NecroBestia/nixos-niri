{ pkgs, config, ... }

let
  obsidian = pkgs.obsidian;  # Reference the Obsidian package from your Nix packages.
in
{
  home.packages = [ obsidian ];  # Ensure Obsidian is included as a package.

  programs.obsidian.enable = true;  # Enable the Obsidian program.
  
  # Optionally, uncomment if you want to specify the package or additional settings.
  # programs.obsidian.package = obsidian;

  # Manage plugins
  programs.obsidian.manageCorePlugins = true;
  programs.obsidian.manageCommunityPlugins = true;
}

