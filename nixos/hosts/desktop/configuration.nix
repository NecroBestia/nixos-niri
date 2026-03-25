{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/bootloader.nix  
    ../../modules/nvidia.nix      
    ../../modules/audio.nix       
    ../../modules/fileManager.nix 
    ../../modules/locale.nix      
    ../../modules/docker.nix      
    ../../modules/services.nix    
    ../../modules/firewall.nix    
    ../../modules/bluetooth.nix   
  ];

  # Identificación de la máquina
  networking.hostName = "desktop"; 
  networking.networkmanager.enable = true;

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

  # Usuario principal
  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    extraGroups = [ "networkmanager" "wheel" "audio" "docker" "input" "storage" ];
    shell = pkgs.bash;
  };

  # Fuentes del sistema
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ]; 

  # Entorno y Paquetes
  # environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Obliga a Electron a usar Wayland
  environment.systemPackages = with pkgs; [
    vim 
    wget 
    git 
    home-manager
    sddm-astronaut
  ];  

  # Display Manager

  # Otros programas y hardware
  programs.dconf.enable = true;
  hardware.opentabletdriver.enable = true;
  console.keyMap = "la-latin1";
  
  #Montaje de disco secundario con variables dinámicas
  fileSystems."/mnt/not_to_lose" = {
    device = "/dev/disk/by-uuid/18324F22324F046A";
    fsType = "ntfs3";
    options = [ 
      "rw" 
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
      "force"
      "x-system.automount"
    ];
  };

  # Optimizaciones de apagado
  systemd = {
    settings.Manager.DefaultTimeoutStopSec = "10s";
    services.opensnitchd.serviceConfig.TimeoutStopSec = lib.mkForce "2s";
  };

  # Mantener esta versión intacta
  system.stateVersion = "25.05"; 
}