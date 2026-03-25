{config, pkgs, ...} : {
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
		package = config.boot.kernelPackages.nvidiaPackages.production;
	};
  	environment.sessionVariables = {
    	GBM_BACKEND = "nvidia-drm";
    	__GLX_VENDOR_LIBRARY_NAME = "nvidia";
    	LIBVA_DRIVER_NAME = "nvidia";
  	};
 }