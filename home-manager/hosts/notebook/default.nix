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
  xdg.configFile."waybar/config.jsonc".source= ../../config/waybar/configNotebook.jsonc;
}
