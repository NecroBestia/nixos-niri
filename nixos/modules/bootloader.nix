{config, pkgs, ...}:{

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
		};
	};
	# Kernel de linux zen. 
	boot.kernelPackages = pkgs.linuxPackages_zen;
	# Soporte NTFS
	boot.supportedFilesystems = [ "ntfs" ];
	# Endurecimiento del Kernel
  
}
