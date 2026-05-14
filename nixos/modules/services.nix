{pkgs, ...}: {
	services = 	
	{
	  # --- Configuracion de SSH ---
    openssh = {
			enable = true;
			ports = [ 22 ];
			settings = 	
			{
				PasswordAuthentication = false;
				KbdInteractiveAuthentication = false; 
				PermitRootLogin = "no"; 
				
			};
		};
    # -- Configuracion Syncthing --- 
    syncthing = {
        enable = true; 
        user = "necro"; 
        configDir="/home/necro/.dataSync"; 
        openDefaultPorts = true;
        systemService = true;
    };
		flatpak.enable = true;	
	};

  #Configuracion xdg
  xdg = {
    autostart.enable = true;
    portal = {
      enable = true;      
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config = {
        common.default = [ "gtk" "gnome" ];
        niri = {
          default = ["gtk" "gnome"];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        };
      };
    };
  };

}
