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
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.10"
    ];
}
