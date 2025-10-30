{pkgs, ...}: {

	services = 	
	{
		openssh = {
			enable = true;
			ports = [ 5432 ];
			settings = 	
			{
				PasswordAuthentication = true;
				KbdInteractiveAuthentication = false; 
				PermitRootLogin = "no"; 
				
			};
		};

		flatpak.enable = true;	
	};
	xdg.portal = {
      		enable = true;
      		wlr.enable = true; # backend Wayland (usado por Niri)
      		extraPortals = with pkgs; [
				xdg-desktop-portal-gnome
        		xdg-desktop-portal-wlr
        		xdg-desktop-portal-gtk
      		];
      		config.common.default = "wlr"; # usa wlr como backend principal
    	};



	
  	environment.sessionVariables = {
    		GTK_USE_PORTAL = "1";
  	};



}
