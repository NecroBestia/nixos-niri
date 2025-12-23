{pkgs, ...}:{

	boot.loader = {
		# Configuracion Grub 		
		efi = {
			canTouchEfiVariables = true;
		};	
		grub = {
			enable = true; 	
			devices = [ "nodev" ];
			efiSupport = true;  
			useOSProber = true; 
      #gfxmodeEfi="1920x1080"; 
      #gfxpayloadEfi = "keep"; 
		};
	};
	# Kernel de linux zen. 
	boot.kernelPackages = pkgs.linuxPackages_zen;
	# Soporte NTFS
	boot.supportedFilesystems = [ "ntfs" ];
	# Endurecimiento del Kernel

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  
  boot.kernelParams = [ 
    "nvidia-drm.modeset=1"
    "quiet"
    "vt.global_cursor_default=0"
    "splash"
  ];
  boot.plymouth = {
    enable = true;
    theme = "breeze"; # O "spinner", "bar", etc.
  };

  # Plymouth tiene que cargar MUY temprano para tapar los glitches
  boot.initrd.systemd.enable = true;


}
