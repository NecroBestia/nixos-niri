# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      	./hardware-configuration.nix
      	./modules/bootloader.nix	#Configuracion Grub  
      	./modules/audio.nix	 	    #Configuracion de audio 
      	./modules/nvidia.nix	 	  #Configuracion de drivers graficos. 
	      ./modules/fileManager.nix #Configuracion Gestor archivos 
	      ./modules/locale.nix		  #Configuracion de hora,moneda, etc
	      ./modules/docker.nix 		  #Configuracion de virtualizacion
	      ./modules/services.nix		#Servicios de ssh, etc. 
        ./modules/firewall.nix    #Configuracion de firewal y opensnitch 
];
  #Security
  security.sudo.enable = true;
  security.apparmor = {
  	enable = true;
  };
  system = 
	{
		autoUpgrade.enable = true;
		autoUpgrade.dates = "weekly";
	};
  nix = {
		gc.automatic = true;
		gc.dates = "daily";
		gc.options = "--delete-older-than 10d";
		settings.auto-optimise-store = true;

	};
  nix.settings.experimental-features =["nix-command" "flakes"];
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking5proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  #Configure keymap in X11
  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };
  nix.settings.download-buffer-size = 524288000;
  # Configure console keymap
  console.keyMap = "la-latin1";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    extraGroups = [ "networkmanager" "wheel" "audio" "docker" "input"];
   # packages = with pkgs; [];
    shell = pkgs.bash;
  };

  #instala todas las fonts de nerdfonts
  fonts.packages = [ ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts) ; 
 
 # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #electron shie 
#  environment.sessionVariables.NIXOS_OZONE_WL = "1";

environment.systemPackages = with pkgs; [
 	vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.xwayland-satellite
	  wget 
	  git 
	  home-manager
	  #Paquete necesarios para niri
	  xwayland-satellite
];	
	#Esta puta mierda hace que funcione niri con el display manager 
	programs.niri.enable = true; 
  services = 
  {
  	displayManager.sddm.enable = true;
  	xserver.enable = true;    
  };
  programs.dconf.enable = true;
	hardware.opentabletdriver.enable = true;


  fileSystems."/mnt/not-to-lose" = {
    device = "/dev/disk/by-uuid/18324F22324F046A";
    fsType = "ntfs";
    options = [ 
    	"rw" 
      "uid=1000" 	#${toString config.users.users.necro.uid}"
      "gid=100"		#${toString config.users.groups.users.gid}"
      "umask=0022"
 	    "windows_names" 
      "nofail" 
     ];
    };
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };

  # 2. Regla específica para OpenSnitch (Asegúrate de poner las comillas "5s")
  # Nota: Verifica el nombre exacto del servicio. Suele ser 'opensnitchd' o 'opensnitch'.
  # Si el comando anterior falló, systemd no sabe qué es 'opensnitchd' si el servicio no se llama así.
  # Para estar seguros, usa el nombre que NixOS le da:
  systemd.services.opensnitchd.serviceConfig.TimeoutStopSec = lib.mkForce "5s";
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
