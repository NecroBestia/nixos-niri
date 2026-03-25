{config, pkgs, pkgs-unstable}:{
  programs = {
    niri.enable 
    package = pkgs-unstable.niri; 
  };
  environment.systemPackages = with pkgs;[
    xwayland-satellite
  ];
  }