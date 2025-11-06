{ config, pkgs, lib, ...}: {
	home = {
		username = "necro";
		homeDirectory = "/home/necro";
		stateVersion = "25.05"; 
		sessionVariables = { 
			GTK_THEME = "Colloid-Dark";
			WAYLAND_DISPLAY ="wayland-0";
			XDG_SESSION_TYPE = "wayland";
  			XDG_CURRENT_DESKTOP = "niri";
  			GDK_BACKEND ="wayland,x11";
  			QT_QPA_PLATFORM = "wayland;xcb";
  			SDL_VIDEODRIVER = "wayland";
  			CLUTTER_BACKEND = "wayland";
		  	MOZ_ENABLE_WAYLAND = "1";
		};

	};
	programs = {
		home-manager.enable = true;  
		waybar.enable = true;
		niri.enable = true;
		obs-studio = {
   			enable = true;
   	 		plugins = with pkgs.obs-studio-plugins; [
     			wlrobs
      			obs-backgroundremoval
      			obs-pipewire-audio-capture
    		];
		};
	};
	# Configuracion alias kitty 

	  programs.bash = {
    		enable = true;

    		# Esto garantiza que Home Manager gestione tu .bashrc
    		enableCompletion = true;
    		initExtra = ''
      		# Puedes añadir otras configuraciones aquí
    		      eval "$(starship init bash)"
		'';

    		shellAliases = {
      			hm-switch = "home-manager switch --flake ~/nixFlake";
      			sys-switch = "sudo nixos-rebuild switch --flake ~/nixFlake";
    			cdev = "nix develop ~/nixFlake#c-dev";
		};
  	};

	nixpkgs.config.allowUnfree = true;

	home.packages = with pkgs; [
		#Consola
		kitty
		starship
		#Aplicaiones consola 
		neofetch
		htop
		tree
		zathura #Lector pdf
		mupdf 
		curl
		#Aplicaciones Graficas
		obsidian
		pavucontrol
		krita
		lorien	
		qalculate-qt
		#Temas GTK		
		colloid-gtk-theme	#Tema GTK
		colloid-icon-theme 	#Tema GTK
		#Background 
		swww 
		swaybg
		imagemagick
		#Servicios 
		playerctl
		cliphist
		wl-clipboard
		hyprshot	
	];
	# Configuracion tema nautilus 
	gtk = {
		enable = true; 
		theme.name = "Colloid-Dark";
		iconTheme.name = "Colloid";
	};


	# Configuracion Archivos de configuracion 
	# fuzzel 
	home.file.".config/fuzzel/fuzzel.ini" = {
		source = lib.mkForce ./config/fuzzel/fuzzel.ini;
	};
	home.file.".config/kitty/kitty.conf".source = lib.mkForce ./config/kitty/kitty.conf;
	home.file.".config/zathura/zathurarc".source = lib.mkForce ./config/zathura/zathurarc;
 	imports  = [
		./modules/niri.nix
		./modules/firefox.nix 
		./modules/waybar.nix
		./modules/wlogout.nix		#./modules/obsidian.nix	
		
	];
	


}

