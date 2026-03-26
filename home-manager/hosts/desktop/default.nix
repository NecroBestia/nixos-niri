{pkgs,...}:{
  imports = [
    ../../shared/default.nix
  ];
  home = {
    username = "necro"; 
    homeDirectory = "/home/necro"; 
    stateVersion = "25.05";
  };
  home.packages = with pkgs; [
    
  ];
  #Configuracion dotfile waybar 
  xdg.configFile."waybar/config.jsonc".source= ../../config/waybar/configDesktop.jsonc;
  }