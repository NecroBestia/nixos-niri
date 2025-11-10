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
# /etc/nixos/configuration.nix

# --- 1. Tu configuración de portal (SIN CAMBIOS) ---
  xdg = {
    autostart.enable = true;
    portal = {
      enable = true;      
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
				xdg-desktop-portal-gnome 
      ];
      config.common.default = [ "wlr" "gtk" ];
    };
  };
}
