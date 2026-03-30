{config, pkgs, pkgs-unstable,  ...} : {
	# OpenGl
	hardware.graphics = {
		enable = true;
		enable32Bit = true; 
		extraPackages = with pkgs; [nvidia-vaapi-driver];
	};
	
	#indicamos el driver para xserver; ni idea de que tan necesario es usando xwayland-
	services.xserver.videoDrivers = ["nvidia"];
 	boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  	boot.kernelParams = [   
   		"nvidia_drm.fbdev=1"
   		"nvidia_drm.modeset=1"
  	];

	hardware.nvidia = {
		modesetting.enable = true; 
		powerManagement.enable = true; 
		powerManagement.finegrained = false;
		# Kernel de nvidia open source. 
		open = false;
		#Configuraciones de nvdia; acceso "nvidia-settings" 
		nvidiaSettings = true; 
		# Version del driver
	package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "570.195.03";
      sha256_64bit = "sha256-1H3oHZpRNJamCtyc+nL+nhYsZfJyL7lgxPUxvXrF3B4=";
      sha256_aarch64 = pkgs.lib.fakeSha256;
      openSha256 = pkgs.lib.fakeSha256;
      
      # ¡Primer hash capturado!
      settingsSha256 = "sha256-mjKkMEPV6W69PO8jKAKxAS861B82CtCpwVTeNr5CqUY="; 
      
      persistencedSha256 = pkgs.lib.fakeSha256;
    };
	};
  	environment.sessionVariables = {
    	GBM_BACKEND = "nvidia-drm";
    	__GLX_VENDOR_LIBRARY_NAME = "nvidia";
    	LIBVA_DRIVER_NAME = "nvidia";
  	};
 }