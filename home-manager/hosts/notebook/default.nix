#===================================================================
# HOME MANAGER — Notebook
#===================================================================
# Configuración específica del usuario para el ThinkPad.
# Hereda toda la configuración compartida de ../shared/default.nix.
#===================================================================
{ pkgs, ... }: {
  imports = [
    ../../shared/default.nix
  ];

  home = {
    username = "necro";
    homeDirectory = "/home/necro";
    stateVersion = "26.05";
  };

  home.packages = with pkgs; [ ];

  programs.noctalia.settings = ../../config/noctalia/configNotebook.toml;
}
