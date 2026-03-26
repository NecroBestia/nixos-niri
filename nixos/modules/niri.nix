{config, pkgs, pkgs-unstable, ...}:{
  programs.niri = {
    enable = true;  
    package = pkgs-unstable.niri; 
  };
  environment.systemPackages = with pkgs;[
    xwayland-satellite
  ];
  }