{pkgs,...}:{
  imports = [
    ../../shared/default.nix
  ];
  home = {
    username = "necro"; 
    homeDirectory = "/home/necro"; 
    stateVersion = "25.05";
  };

}
