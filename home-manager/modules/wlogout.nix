{lib, ...}:{
	
	programs.wlogout.enable = true;
	
	# Archivos de Configuracion 
	home.file.".config/wlogout/icons" = lib.mkForce {
		source = ../config/wlogout/icons;
		recursive = true;
	};
	home.file.".config/wlogout/layout".source = lib.mkForce ../config/wlogout/layout;
	home.file.".config/wlogout/style.css".source = lib.mkForce ../config/wlogout/style.css;
}
