{ pkgs, pkgs-unstable, ... }: 
let
  # Variables globales para cambiar de tema fácilmente en el futuro
  themeName = "Colloid-Dark";
  cursorName = "Bibata-Modern-Ice";
  cursorSize = 24;

  MyTerminal = "kitty";  
  # Importamos el archivo de scripts UNA SOLA VEZ
  myScripts = import ../modules/scripts.nix { inherit pkgs; };
in { 
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);

  home = {
    stateVersion = "25.05"; 
    
    shellAliases = { 
      hm-switch = "home-manager switch --flake ~/nixFlake#\"necro@$HOSTNAME\""; 
      sys-switch = "sudo nixos-rebuild switch --flake ~/nixFlake#$HOSTNAME";
    };

    pointerCursor = {
      name = cursorName;
      package = pkgs.bibata-cursors;
      size = cursorSize;
      gtk.enable = true;
      x11.enable = true;
    };
    
    sessionVariables = { 
      GTK_THEME = themeName; 
      XDG_SESSION_TYPE = "wayland"; 
      XDG_CURRENT_DESKTOP = "niri"; 
      XDG_SESSION_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland;xcb"; 
      XCURSOR_THEME = cursorName;
      XCURSOR_SIZE = toString cursorSize;
      TERMINAL = MyTerminal; 
    };

    # Paquetes ordenados y divididos por rama
    packages = with pkgs; [ 
      # Sistema y Terminal (Estables)
      kitty starship neofetch htop tree curl nil direnv nix-direnv 
      
      # Entorno Gráfico Wayland (Estables)
      wlsunset playerctl wl-clipboard swww swayidle swaybg gsimplecal qalculate-qt 
      
      # Multimedia y Edición (Estables)
      pavucontrol nomacs vlc 

      # --- PAQUETES INESTABLES (Última versión) ---
      pkgs-unstable.krita
      pkgs-unstable.spotify
      pkgs-unstable.obsidian
      pkgs-unstable.vscodium 
      pkgs-unstable.zathura
      pkgs-unstable.mupdf 
      pkgs-unstable.libreoffice-qt-fresh 
      pkgs-unstable.xournalpp
      # Scripts locales
      myScripts.clipboard
      myScripts.niri-wallpaper
    ];
  };

  # Unificamos todos los programas en un solo bloque
  programs = {
    home-manager.enable = true;      
    waybar.enable = true;        
    
    bash = {
      enable = true; 
      enableCompletion = true; 
    };
    
    starship = {
      enable = true;
      enableBashIntegration = true;
    };

    direnv = {
      enable = true; 
      enableBashIntegration = true; 
      nix-direnv.enable = true; 
    }; 
  };

  gtk = { 
    enable = true; 
    theme = { name = themeName; package = pkgs.colloid-gtk-theme; };
    iconTheme = { name = "Colloid"; package = pkgs.colloid-icon-theme; };
    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
  };

  qt = {
    enable = true; 
    platformTheme.name = "gtk";
    style.name = themeName; 
  };
  
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  
  services = {
    cliphist = { enable = true; package = pkgs.cliphist; };
    udiskie = { enable = true; automount = true; notify = true; tray = "auto"; };
  };
  
  xdg= {
    mimeApps = { 
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
    desktopEntries = {
      xterm = {
        name = "XTerm"; 
        exec = "xterm"; 
        noDisplay = true; 
      }; 
      nvim = {
        name = "Neovim";
        icon = "nvim";
        genericName = "Text Editor";
        # Nix reemplazará ${myTerminal} por "kitty" al compilar
        exec = "${MyTerminal} -e nvim %F"; 
        terminal = false; 
        categories = [ "Utility" "TextEditor" ];
        mimeType = [ "text/plain" "text/markdown" ];
      };
      vim = {
        name = "Vim";
        exec = "vim";
        noDisplay = true;
      };
      
      # --- Ocultar GVim ---
      gvim = {
        name = "GVim";
        exec = "gvim";
        noDisplay = true;
      };
    };
  };

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