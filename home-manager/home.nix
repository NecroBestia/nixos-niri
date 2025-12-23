{ pkgs, lib, ...}: {

  # --- 1. Configuración Central de Home Manager ---
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
    
    # Variables de sesión
    sessionVariables = { 
      GTK_THEME = "Colloid-Dark"; 
#      WAYLAND_DISPLAY ="wayland-0"; 
      XDG_SESSION_TYPE = "wayland"; 
      XDG_CURRENT_DESKTOP = "niri"; 
      XDG_SESSION_DESKTOP = "niri";
#      GDK_BACKEND ="wayland,x11"; 
      QT_QPA_PLATFORM = "wayland;xcb"; 
#      SDL_VIDEODRIVER = "wayland"; 
#      CLUTTER_BACKEND = "wayland"; 
#      MOZ_ENABLE_WAYLAND = "1"; 
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
    vscodium    
    # Aplicaciones Gráficas
    obsidian
    pavucontrol
    krita
    lorien	
    qalculate-qt
    vlc
    # Utilidades de Escritorio y Wayland
    playerctl
    #cliphist
    wl-clipboard
    hyprshot
    swww 
    swaybg
    imagemagick
    swayidle
    # NOTA: Quité 'colloid-gtk-theme' y 'colloid-icon-theme' de aquí
    # porque los estás manejando correctamente en la sección 'gtk' más abajo.
    # Tenerlos en ambos lugares es redundante.
  ];

  # --- 3. Configuración de Shell y Terminal ---
  programs.bash = {
    enable = true; 
    enableCompletion = true; 
    # 'initExtra' se mantiene, pero los alias se movieron a 'home.aliases'
  # initExtra = ''
  #    eval "$(starship init bash)"
  #  ''; 
  };
  
  # (Recomendación) Puedes reemplazar 'eval' en bash.initExtra
  # simplemente activando el módulo de starship:
   programs.starship = {
     enable = true;
     enableBashIntegration = true;
   };

  # --- 4. Configuración de GUI (Temas, Iconos, MIME) ---
  # Define tu tema GTK y de iconos./* 
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
      "inode/directory" = "org.gnome.Nautilus.desktop"; 
      "application/pdf" = ["org.pwmt.zathura.desktop"  "firefox.desktop"];
    };
  };

  # --- 5. Configuración de Programas Específicos ---
  # Agrupa todos los 'programs.*'
  programs = {
    home-manager.enable = true; 
    
    waybar = { 
      enable = true;
      # (La configuración se maneja en ./modules/waybar.nix)
    	
    };
    
   #niri.enable = true; # (Comentado en tu original)

    # obs-studio = { 
      # enable = true;
      # plugins = with pkgs.obs-studio-plugins; [ 
      #  wlrobs
      #  obs-backgroundremoval
      #  obs-pipewire-audio-capture
      #]; 
      #};
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
    ".config/scripts/" = { 
      source = lib.mkForce ./config/scripts; 
      recursive = true; 
    };
#    ".config/mako/config" = {
#      source = lib.mkForce ./config/mako/config;
#    };
  };

  # --- 7. Módulos Externos ---
  # Los 'imports' suelen ir al final o al principio.
  imports  = [
    ./modules/niri.nix
    ./modules/firefox.nix 
    ./modules/waybar.nix
    ./modules/nvim.nix
    ./modules/wlogout.nix			
  ];
  
}
