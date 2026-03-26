{ pkgs, lib, ...}: { 
  home = {
    stateVersion = "25.05"; 
    shellAliases = { 
      hm-switch = "home-manager switch --flake ~/nixFlake#\"necro@$HOSTNAME\""; 
      sys-switch = "sudo nixos-rebuild switch --flake ~/nixFlake#$HOSTNAME";
    };
    pointerCursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
    
    sessionVariables = { 
      GTK_THEME = "Colloid-Dark"; 
      XDG_SESSION_TYPE = "wayland"; 
      XDG_CURRENT_DESKTOP = "niri"; 
      XDG_SESSION_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland;xcb"; 
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate =(_:true);

  # Paquetes comunes para AMBOS equipos
  home.packages = with pkgs; [ 
    kitty starship neofetch htop tree curl nil direnv nix-direnv wlsunset
    zathura mupdf 
    obsidian pavucontrol krita qalculate-qt vlc xournalpp nomacs vscodium libreoffice-qt-fresh    
    playerctl wl-clipboard swww swayidle swaybg gsimplecal 
    # Importación correcta de tus scripts como módulos de Home Manager
    (import ../modules/scripts.nix {inherit pkgs;}).clipboard
    (import ../modules/scripts.nix {inherit pkgs;}).niri-wallpaper
  ];

  programs = {
    bash = {
      enable = true; 
      enableCompletion = true; 
    };
    starship = {
      enable = true;
      enableBashIntegration = true;
      };
  };

  gtk = { 
    enable = true; 
    theme = { name = "Colloid-Dark"; package = pkgs.colloid-gtk-theme; };
    iconTheme = { name = "Colloid"; package = pkgs.colloid-icon-theme; };
    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
  };
  qt = {
    enable = true; 
    platformTheme.name = "gtk";
    style.name = "Colloid-Dark"; 
  };
  
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  
  services.cliphist = { enable = true; package = pkgs.cliphist; };
  services.udiskie = { enable=true; automount = true; notify= true; tray="auto"; };
  
  xdg.mimeApps = { 
    enable = true; 
    defaultApplications = {
      "inode/directory" = ["org.gnome.Nautilus.desktop"]; 
      "application/pdf" = ["org.pwmt.zathura.desktop"  "firefox.desktop"];
      "image/png"  = ["org.nomacs.ImageLounge.desktop"];
      "image/jpeg" = ["org.nomacs.ImageLounge.desktop"]; 
      "image/webp" = ["org.nomacs.ImageLounge.desktop"]; 
      "image/gif"  = ["org.nomacs.ImageLounge.desktop"];
      "image/svg+xml" = ["org.nomacs.ImageLounge.desktop"]; 
    };
  };

  programs = {
    home-manager.enable = true; 
    waybar.enable = true;      
    direnv.enable = true; 
  };

  # enlazarlos config files
  home.file = {
    ".config/fuzzel/fuzzel.ini".source = ../config/fuzzel/fuzzel.ini; 
    ".config/kitty/kitty.conf".source = ../config/kitty/kitty.conf; 
    ".config/zathura/zathurarc".source = ../config/zathura/zathurarc; 
  };

  imports  = [
    ../modules/niri.nix
    ../modules/firefox.nix 
    ../modules/waybar.nix
    ../modules/nvim.nix
    ../modules/wlogout.nix     
    ../modules/systemd.nix
  ];
}