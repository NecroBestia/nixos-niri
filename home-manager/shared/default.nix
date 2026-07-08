#===================================================================
# HOME MANAGER — Configuración Compartida (Ambos Hosts)
#===================================================================
# Configuración de usuario que aplica tanto a desktop como notebook.
# Cada host tiene su propio archivo home-manager/hosts/<host>/default.nix
# que importa este shared y añade lo específico (como el json de Waybar).
#
# VARIABLES GLOBALES:
#   themeName, cursorName, cursorSize, MyTerminal → Cambia aquí
#   y se refleja en GTK, Qt, shell, y atajos.
#===================================================================
{ pkgs, pkgs-unstable, ... }:
let
  themeName = "Colloid-Dark";
  cursorName = "Bibata-Modern-Ice";
  cursorSize = 24;
  MyTerminal = "kitty";

  # Scripts personalizados (clipboard, wallpaper, spotify).
  myScripts = import ../modules/scripts.nix { inherit pkgs; };
in {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);

  home = {
    stateVersion = "26.05";

    #-----------------------------------------------------------------
    # SHELL ALIASES
    #-----------------------------------------------------------------
    # hm-switch: Reconstruye Home Manager para el host actual.
    #   $HOSTNAME se expande en el shell (desktop/notebook).
    #   Ejemplo: home-manager switch --flake ~/nixFlake#"necro@desktop"
    #
    # sys-switch: Reconstruye NixOS para el host actual.
    #-----------------------------------------------------------------
    shellAliases = {
      hm-switch = "home-manager switch --flake ~/nixFlake#\"necro@$HOSTNAME\"";
      sys-switch = "sudo nixos-rebuild switch --flake ~/nixFlake#$HOSTNAME";
    };

    #-----------------------------------------------------------------
    # CURSOR
    #-----------------------------------------------------------------
    # Bibata-Modern-Ice: Tema de cursor moderno (blanco/hielo).
    # Habilitado tanto para GTK como X11 para consistencia.
    pointerCursor = {
      name = cursorName;
      package = pkgs.bibata-cursors;
      size = cursorSize;
      gtk.enable = true;
      x11.enable = true;
    };

    #-----------------------------------------------------------------
    # VARIABLES DE SESIÓN
    #-----------------------------------------------------------------
    # Fuerzan Wayland en todas las apps que lo soporten.
    # QT_QPA_PLATFORM = "wayland;xcb": Prefiere Wayland, fallback X11.
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

    #-----------------------------------------------------------------
    # PAQUETES DE USUARIO
    #-----------------------------------------------------------------
    # Divididos por categoría para facilitar el mantenimiento.
    # Los paquetes "unstable" son la excepción (necesitan versión
    # reciente). El resto usa nixpkgs estable.
    packages = with pkgs; [
      # Sistema y Terminal
      kitty starship fastfetch htop tree curl nil direnv
      nix-direnv libreoffice gh

      # Entorno Gráfico Wayland
      wlsunset playerctl wl-clipboard awww swayidle swaybg
      gsimplecal qalculate-qt

      # Multimedia y Edición
      pavucontrol nomacs vlc zathura mupdf

      # Inestables (Última versión desde nixpkgs-unstable)
      pkgs-unstable.krita      # Ilustración digital.
      pkgs-unstable.obsidian   # Notas Markdown con graph view.
      pkgs-unstable.vscodium   # VS Code sin telemetría.
      pkgs-unstable.xournalpp  # Anotaciones en PDF.
      pkgs-unstable.opencode   # Cliente de Claude para terminal.

      # Scripts locales
      myScripts.clipboard       # Historial del portapapeles con fuzzel.
      myScripts.niri-wallpaper  # Gestor de fondos con blur + awww.
      myScripts.spotify-startup # Lanzador condicional (Flatpak/nativo).
    ];
  };

  #-----------------------------------------------------------------
  # PROGRAMAS
  #-----------------------------------------------------------------
  programs = {
    home-manager.enable = true;
    waybar.enable = true;

    bash = {
      enable = true;
      enableCompletion = true;
    };

    starship = {
      enable = true;              # Prompt minimalista y rápido.
      enableBashIntegration = true;
    };

    direnv = {
      enable = true;              # Carga automática de .envrc.
      enableBashIntegration = true;
      nix-direnv.enable = true;   # Caché de direnv para flakes.
    };
  };

  #-----------------------------------------------------------------
  # APARIENCIA (GTK + Qt + DConf)
  #-----------------------------------------------------------------
  gtk = {
    enable = true;
    theme = { name = themeName; package = pkgs.colloid-gtk-theme; };
    iconTheme = { name = "Colloid"; package = pkgs.colloid-icon-theme; };
    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";  # Qt sigue el tema GTK.
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  #-----------------------------------------------------------------
  # SERVICIOS DE USUARIO
  #-----------------------------------------------------------------
  services = {
    # cliphist: Historial del portapapeles con soporte de imágenes.
    #   bind: Mod+Ctrl+V (definido en binds.kdl de Niri).
    cliphist = { enable = true; package = pkgs.cliphist; };

    # udiskie: Montaje automático de discos extraíbles.
    #   No requiere sudo, notifica con mako.
    udiskie = { enable = true; automount = true; notify = true; tray = "auto"; };
  };

  #-----------------------------------------------------------------
  # XDG — MIME y Entradas de Escritorio
  #-----------------------------------------------------------------
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "application/pdf" = [ "org.pwmt.zathura.desktop" "firefox.desktop" ];
        "image/png"  = [ "org.nomacs.ImageLounge.desktop" ];
        "image/jpeg" = [ "org.nomacs.ImageLounge.desktop" ];
        "image/webp" = [ "org.nomacs.ImageLounge.desktop" ];
        "image/gif"  = [ "org.nomacs.ImageLounge.desktop" ];
        "image/svg+xml" = [ "org.nomacs.ImageLounge.desktop" ];
      };
    };

    desktopEntries = {
      xterm = { name = "XTerm"; exec = "xterm"; noDisplay = true; };
      nvim = {
        name = "Neovim";
        icon = "nvim";
        genericName = "Text Editor";
        exec = "${MyTerminal} -e nvim %F";
        terminal = false;
        categories = [ "Utility" "TextEditor" ];
        mimeType = [ "text/plain" "text/markdown" ];
      };
      vim  = { name = "Vim";  exec = "vim";  noDisplay = true; };
      gvim = { name = "GVim"; exec = "gvim"; noDisplay = true; };
    };
  };

  #-----------------------------------------------------------------
  # DOTFILES — Enlaces Simbólicos
  #-----------------------------------------------------------------
  # Conectan los archivos de configuración (en config/) con sus
  # ubicaciones esperadas (~/.config/).
  home.file = {
    ".config/fuzzel/fuzzel.ini".source  = ../config/fuzzel/fuzzel.ini;
    ".config/kitty/kitty.conf".source   = ../config/kitty/kitty.conf;
    ".config/zathura/zathurarc".source  = ../config/zathura/zathurarc;
  };

  #-----------------------------------------------------------------
  # MÓDULOS DE HOME MANAGER
  #-----------------------------------------------------------------
  imports = [
    ../modules/niri.nix      # Niri + swayidle + polkit + keyring.
    ../modules/firefox.nix   # Firefox desde unstable.
    ../modules/waybar.nix    # Barra de estado Waybar.
    ../modules/nvim.nix      # Neovim aislado con LSPs.
    ../modules/wlogout.nix   # Menú de apagado/reinicio.
    ../modules/systemd.nix   # wlsunset (filtro luz azul + timer 10PM).
  ];
}
