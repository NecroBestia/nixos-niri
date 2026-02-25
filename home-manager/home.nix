{ pkgs, lib, ...}: { # --- 1. Configuración Central de Home Manager ---
  # Define el usuario, el directorio y la versión de estado.
  home = {
    username = "necro"; 
    homeDirectory = "/home/necro"; 
    stateVersion = "25.05"; 

    # Mover los alias aquí es más limpio que en 'programs.bash'.
    # Así estarán disponibles en zsh, fish, etc., si alguna vez cambias.
    shellAliases = { 
      hm-switch = "home-manager switch --flake ~/nixFlake"; 
      sys-switch = "sudo nixos-rebuild switch --flake ~/nixFlake";
      cdev = "nix develop ~/nixFlake#c-dev"; 
#     mvuni  = "cd /mnt/not-to-lose/SyncThing/Universidad/";
  };
    pointerCursor = {
      name = "Bibata-Modern-Ice"; # El nombre exacto del tema (dentro de la carpeta del paquete)
      package = pkgs.bibata-cursors; # El paquete de Nix
      size = 24;
      gtk.enable = true; # Aplica esto a aplicaciones GTK
      x11.enable = true; # Aplica esto a XWayland
    };
    
    # Variables de sesión
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

  # --- 2. Gestión de Paquetes ---
  # Habilitar paquetes no libres (como OBS)
  nixpkgs.config.allowUnfree = true;

  # Lista principal de paquetes instalados
  home.packages = with pkgs; [ 
    # Consola y Terminal
    kitty
    starship
    neofetch
    htop
    tree
    curl
    nil
    # Aplicaciones de Consola
    zathura # Lector pdf
    mupdf 
    # Aplicaciones Gráficas
    obsidian
    pavucontrol
    krita
    qalculate-qt
    vlc
    xournalpp 
    nomacs 
    vscodium
    libreoffice-qt-fresh    
    # Utilidades de Escritorio y Wayland
    playerctl
    #cliphist
    wl-clipboard
    swww 
    swayidle
    #scripts 
    (import ./modules/scripts.nix {inherit pkgs;}).clipboard
    (import ./modules/scripts.nix {inherit pkgs;}).niri-wallpaper
  ];

  # --- 3. Configuración de Shell y Terminal ---
  programs.bash = {
    enable = true; 
    enableCompletion = true; 
  };
  
  # (Recomendación) Puedes reemplazar 'eval' en bash.initExtra
  # simplemente activando el módulo de starship:
   programs.starship = {
     enable = true;
     enableBashIntegration = true;
   };

  # --- 4. Configuración de GUI (Temas, Iconos, MIME) ---
  # Define tema GTK y de iconos./* 
  gtk = { 
    enable = true; 
    theme = {
      name = "Colloid-Dark"; 
      package = pkgs.colloid-gtk-theme;  #Define el paquete aquí
    };
    iconTheme = {
      name = "Colloid"; 
      package = pkgs.colloid-icon-theme;  #Define el paquete aquí
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
  qt = {
    enable = true; 
    platformTheme.name = "gtk";
    style.name = "Colloid-Dark"; 
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme  = "prefer-dark";
    };
  };
  # Configuracion cliphist 
  services.cliphist = {
    enable = true;
    package = pkgs.cliphist;
  };
  # Configuración de aplicaciones por defecto (MIME types)
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

  # --- 5. Configuración de Programas Específicos ---
  # Agrupa todos los 'programs.*'
  programs = {
    home-manager.enable = true; 
    waybar = { 
      enable = true;    	
    };
  };
  # --- 6. Gestión de Archivos de Configuración (Dotfiles) ---
  # Agrupa todos los 'home.file' para mayor claridad
  home.file = {
    ".config/fuzzel/fuzzel.ini" = { 
      source = lib.mkForce ./config/fuzzel/fuzzel.ini; 
    };
    ".config/kitty/kitty.conf" = { 
      source = lib.mkForce ./config/kitty/kitty.conf; 
    };
    ".config/zathura/zathurarc" = { 
      source = lib.mkForce ./config/zathura/zathurarc; 
    };
  };

  # --- 7. Módulos Externos ---
  imports  = [
    ./modules/niri.nix
    ./modules/firefox.nix 
    ./modules/waybar.nix
    ./modules/nvim.nix
    ./modules/wlogout.nix			
  ];
  
}
