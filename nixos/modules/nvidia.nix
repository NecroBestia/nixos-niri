{config, pkgs, ...} : {
	# OpenGl
	hardware.graphics = {
		enable = true;
		enable32Bit = true; 
		extraPackages = with pkgs; [nvidia-vaapi-driver];
	};
	 
	#indicamos el driver para xserver; ni idea de que tan necesario es usando xwayland-
	services.xserver.videoDrivers = ["nvidia"];

	hardware.nvidia = {
		modesetting.enable = true; 
		powerManagement.enable = false; 
		powerManagement.finegrained = false;
	# Kernel de nvidia open source. 
	open = false;
	#Configuraciones de nvdia; acceso "nvidia-settings" 
	nvidiaSettings = true; 
	
	# Version del driver
	package = config.boot.kernelPackages.nvidiaPackages.stable;
	};
  	environment.sessionVariables = {
    	GBM_BACKEND = "nvidia-drm";
    	__GLX_VENDOR_LIBRARY_NAME = "nvidia";
    	LIBVA_DRIVER_NAME = "nvidia";
    		NVD_BACKEND = "direct";
  	};

  	}
