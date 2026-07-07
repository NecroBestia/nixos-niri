{
  pkgs,
  inputs,
  ...
}:
let
  pkgs-kernel = import inputs.nixpkgs-kernel {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ../shared/default.nix
    ../../modules/nvidia.nix
    ../../modules/firewall.nix
    ../../modules/steam.nix
  ];

  # Identificación de la máquina
  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  # 2. Configuración de Resume (Hibernación)
  # Usuario principal
  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "docker"
      "input"
      "storage"
    ];
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
      "x-gvfs-name=not_to_lose"
      "x-gvfs-show"
      "x-systemd.automount"
    ];
  };
  fileSystems."/mnt/neverToLose" = {
    device = "/dev/disk/by-uuid/3EFA7B8AFA7B3D69";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
      "force"
      "x-gvfs-name=neverToLose"
      "x-gvfs-show"
      "x-systemd.automount"
    ];
  };
  fileSystems."/mnt/juegos" = {
    device = "/dev/disk/by-uuid/9E207F36207F150D";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
      "force"
      "x-gvfs-name=juegos"
      "x-gvfs-show"
      "x-systemd.automount"
    ];
  };
  # Montaje del disco para uso de syncthing
  services.syncthing = {
    dataDir = "/mnt/not_to_lose/SyncThing";
  };
  systemd.services.syncthing = {
    bindsTo = [ "mnt-not_to_lose.mount" ];
    after = [ "mnt-not_to_lose.mount" ];
  };

  boot.kernelPackages = pkgs.linuxPackagesFor pkgs-kernel.linuxPackages_zen.kernel;
  # Mantener esta versión intacta
  system.stateVersion = "25.05";
}
