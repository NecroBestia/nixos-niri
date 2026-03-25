{pkgs, config, ...}:{
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "latam";
        variant = "";
      };
    };
    displayManager.sddm = {
      enable = true;
      theme = "sddm-astronaut-theme"; 
      settings = {
        General = {
          InputMethod = "";
        };
      };
      extraPackages = with pkgs; [
        sddm-astronaut
        kdePackages.qtmultimedia 
        kdePackages.qtsvg        
        kdePackages.qt5compat
      ];
    };
  };

}