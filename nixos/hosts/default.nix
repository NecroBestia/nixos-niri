{pkgs, ...}:{
  imports = [
    ../modules/bootloader.nix  
    ../modules/audio.nix       
    ../modules/fileManager.nix 
    ../modules/locale.nix      
    ../modules/bluetooth.nix
    ../modules/niri.nix 
    ../modules/displayManager.nix 
    ../modules/docker.nix      
    ../modules/services.nix    
  ];

   console.keyMap = "la-latin1";
  
  # Fonts sistema 
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono

  ]; 
  # Configuraciones del gestor de paquetes Nix agrupadas
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      download-buffer-size = 524288000;
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 10d";
    };
  };
  nixpkgs.config.allowUnfree = true; 
  # Seguridad básica
  security = {
    sudo.enable = true; 
    apparmor.enable = true; 
    polkit.enable = true; 
  }; 

  environment.systemPackages = with pkgs; [
    vim 
    wget 
    git 
    home-manager
    sddm-astronaut
    htop
    papirus-icon-theme
  ];  
  xdg.icons.enable =true;


}
