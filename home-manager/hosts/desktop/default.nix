{pkgs, pkgs-unstable, ...}:{
  imports = [
    ../../shared/default.nix
  ];
  home = {
    username = "necro"; 
    homeDirectory = "/home/necro"; 
    stateVersion = "26.05";
  };
  home.packages = [

  ]; 
  #Configuracion dotfile waybar 
  xdg.configFile."waybar/config.jsonc".source= ../../config/waybar/configDesktop.jsonc;
  }
