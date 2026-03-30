{lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../default.nix
    ../../modules/nvidia.nix      
    ../../modules/firewall.nix      
  ];

  # Identificación de la máquina
  networking.hostName = "desktop"; 
  networking.networkmanager.enable = true;

  # Usuario principal
  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    extraGroups = [ "networkmanager" "wheel" "audio" "docker" "input" "storage" ];
    shell = pkgs.bash;
  };

  # environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Obliga a Electron a usar Wayland
  # Otros programas y hardware
  programs.dconf.enable = true;
  hardware.opentabletdriver.enable = true;
 
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
  # Montaje del disco para uso de syncthing 
  services.syncthing = {
    dataDir = "/mnt/not_to_lose/SyncThing";  
  };
  systemd.services.syncthing = {
    bindsTo = ["mnt-not_to_lose.mount"];
    after = ["mnt-not_to_lose.mount"];
  };
  # Optimizaciones de apagado
  systemd = {
    settings.Manager.DefaultTimeoutStopSec = "10s";
    services.opensnitchd.serviceConfig.TimeoutStopSec = lib.mkForce "2s";
  };

  # Mantener esta versión intacta
  system.stateVersion = "25.05"; 
}
