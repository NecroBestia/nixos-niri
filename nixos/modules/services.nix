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
# En nixos/modules/services.nix

  	xdg.portal = {
    		enable = true;
    
    		# Deshabilitamos la opción 'wlr.enable' para tener control total
    		wlr.enable = false; 
    
    		# Habilitamos manualmente SOLO los portales que Niri necesita:
    		# 1. 'wlr' para la selección de ventanas
    		# 2. 'gtk' para los selectores de archivos (como "Abrir archivo...")
    		extraPortals = with pkgs; [
      			xdg-desktop-portal-wlr
      			xdg-desktop-portal-gtk
			xdg-desktop-portal-gnome
    		];

    		# Forzamos al sistema a preferir 'wlr' sobre cualquier otro
    		config.common.default = [ "gtk" ];
  	};

}
