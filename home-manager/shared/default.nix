#===================================================================
# HOME MANAGER — Configuración Compartida (Ambos Hosts)
#===================================================================
# Configuración de usuario que aplica tanto a desktop como notebook.
# Cada host tiene su propio archivo home-manager/hosts/<host>/default.nix
# que importa este shared y añade lo específico (como el json de Waybar).
#
# VARIABLES GLOBALES:
#   cursorName, cursorSize, MyTerminal → Cambia aquí
#   y se refleja en cursor, shell, y atajos.
#===================================================================
{ config, pkgs, pkgs-unstable, ... }:
let
  cursorName = "Bibata-Modern-Ice";
  cursorSize = 24;
  MyTerminal = "kitty";

  # Scripts personalizados (spotify, symlinks).
  myScripts = import ../modules/scripts.nix { inherit pkgs; };
in {
  nixpkgs.config.allowUnfree = true;

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
      nvidia-settings = "nvidia-settings --config='${config.xdg.configHome}/nvidia/settings'";
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
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland;xcb";
      XCURSOR_THEME = cursorName;
      XCURSOR_SIZE = toString cursorSize;
      TERMINAL = MyTerminal;

      # Redireccion XDG para dotfiles de historial
      HISTFILE = "$XDG_STATE_HOME/bash/history";
      IPYTHONDIR = "$XDG_CONFIG_HOME/ipython";
      NODE_REPL_HISTORY = "$XDG_DATA_HOME/node_repl_history";
      PYTHON_HISTORY = "$XDG_STATE_HOME/python_history";
    };

    #-----------------------------------------------------------------
    # PAQUETES DE USUARIO
    #-----------------------------------------------------------------
    # Divididos por categoría para facilitar el mantenimiento.
    # Los paquetes "unstable" son la excepción (necesitan versión
    # reciente). El resto usa nixpkgs estable.
    packages = with pkgs; [
      # Sistema y Terminal
      kitty starship fastfetch tree curl nil        # direnv removido: ya configurado via programs.direnv.
      libreoffice gh libnotify btop                   # nix-direnv removido: idem.

      # Entorno Gráfico Wayland
      playerctl wl-clipboard                            # swayidle removido: redundante.
      gsimplecal

      # Multimedia y Edición
      pavucontrol nomacs vlc zathura mupdf qalculate-qt
      pkgs.devenv            # Entornos dev declarativos con servicios

      # Inestables (Última versión desde nixpkgs-unstable)
      pkgs-unstable.krita      # Ilustración digital.
      pkgs-unstable.obsidian   # Notas Markdown con graph view.
      pkgs-unstable.vesktop   # Discord client con Vencord integrado.
      pkgs-unstable.vscodium   # VS Code sin telemetría.
      pkgs-unstable.xournalpp  # Anotaciones en PDF.
      pkgs-unstable.opensnitch-ui # Firewall interactivo (GUI)

      # Scripts locales
      myScripts.spotify-startup # Lanzador condicional (Flatpak/nativo).
      myScripts.niri-symlinks   # Creador de enlaces simbólicos.
    ];
  };

  #-----------------------------------------------------------------
  # PROGRAMAS
  #-----------------------------------------------------------------
  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      enableCompletion = true;
      historyFile = "${config.xdg.stateHome}/bash/history";
    };

    starship = {
      enable = true;              # Prompt minimalista y rápido.
      enableBashIntegration = true;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    git = {
      enable = true;
      settings = {
        user.name = "necrobestia";
        user.email = "necrobestiaa@gmail.com";
        credential."https://github.com".helper = [ "" "!${config.home.homeDirectory}/.nix-profile/bin/.gh-wrapped auth git-credential" ];
        credential."https://gist.github.com".helper = [ "" "!${config.home.homeDirectory}/.nix-profile/bin/.gh-wrapped auth git-credential" ];
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };

  };

  #-----------------------------------------------------------------
  # APARIENCIA (GTK + Qt + DConf)
  #-----------------------------------------------------------------
  # Noctalia maneja colores GTK vía templates built-in (gtk.css).
  # Home-manager agrega gtk-application-prefer-dark-theme=1 en
  # settings.ini que Noctalia no toca, más dconf color-scheme.
  gtk = {
    enable = true;
    colorScheme = "dark";
    iconTheme = { name = "Colloid"; package = pkgs.colloid-icon-theme; };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt6;
    };
  };

  #-----------------------------------------------------------------
  # SERVICIOS DE USUARIO
  #-----------------------------------------------------------------
  services = {
    # udiskie: Montaje automático de discos extraíbles.
    #   No requiere sudo, notifica con Noctalia.
    udiskie = { enable = true; automount = true; notify = true; tray = "auto"; };
  };

  #-----------------------------------------------------------------
  # XDG — MIME y Entradas de Escritorio
  #-----------------------------------------------------------------
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Navegador
        "x-scheme-handler/http"  = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "text/html"              = [ "firefox.desktop" ];

        # Archivos
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];

        # Texto y código
        "text/plain"            = [ "nvim.desktop" ];
        "text/markdown"         = [ "nvim.desktop" ];
        "application/json"      = [ "nvim.desktop" ];
        "application/xml"       = [ "nvim.desktop" ];
        "application/x-yaml"    = [ "nvim.desktop" ];
        "text/x-nix"            = [ "nvim.desktop" ];
        "text/x-python"         = [ "nvim.desktop" ];
        "text/x-shellscript"    = [ "nvim.desktop" ];

        # PDF
        "application/pdf" = [ "org.pwmt.zathura.desktop" "firefox.desktop" ];

        # Imágenes
        "image/png"    = [ "org.nomacs.ImageLounge.desktop" ];
        "image/jpeg"   = [ "org.nomacs.ImageLounge.desktop" ];
        "image/webp"   = [ "org.nomacs.ImageLounge.desktop" ];
        "image/gif"    = [ "org.nomacs.ImageLounge.desktop" ];
        "image/svg+xml"= [ "org.nomacs.ImageLounge.desktop" ];
        "image/bmp"    = [ "org.nomacs.ImageLounge.desktop" ];
        "image/tiff"   = [ "org.nomacs.ImageLounge.desktop" ];

        # Audio
        "audio/mpeg"      = [ "vlc.desktop" ];
        "audio/ogg"       = [ "vlc.desktop" ];
        "audio/flac"      = [ "vlc.desktop" ];
        "audio/wav"       = [ "vlc.desktop" ];
        "audio/x-m4a"     = [ "vlc.desktop" ];
        "audio/x-matroska"= [ "vlc.desktop" ];

        # Video
        "video/mp4"       = [ "vlc.desktop" ];
        "video/mpeg"      = [ "vlc.desktop" ];
        "video/x-matroska"= [ "vlc.desktop" ];
        "video/webm"      = [ "vlc.desktop" ];
        "video/avi"       = [ "vlc.desktop" ];
        "video/x-msvideo" = [ "vlc.desktop" ];
        "video/quicktime" = [ "vlc.desktop" ];
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
    ".config/kitty/kitty.conf".source   = ../config/kitty/kitty.conf;
    ".config/zathura/zathurarc".source  = ../config/zathura/zathurarc;
    ".config/sioyek/keys_user.config".source  = ../config/sioyek/keys_user.config;
    ".config/sioyek/prefs_user.config".source = ../config/sioyek/prefs_user.config;

    # Thumbnailer para PDF (pdftoppm viene con poppler-utils)
    # Flags clave:
    #   -singlefile | Solo primera página (antes renderizaba todas → lento)
    #   -f 1 -l 1   | Refuerza página única
    #   sh wrapper  | Saca .png de %o porque pdftoppm lo agrega solo
    ".local/share/thumbnailers/pdf-thumbnailer.thumbnailer".text = ''
      [Thumbnailer Entry]
      TryExec=pdftoppm
      Exec=sh -c 'exec pdftoppm -png -scale-to 1024 -singlefile -f 1 -l 1 "$1" "$(dirname "$2")/$(basename "$2" .png)"' -- %i %o
      MimeType=application/pdf;
    '';

    # TUI plugins para OpenCode (sidebars de monitoreo)
    ".config/opencode/tui.jsonc".text = builtins.toJSON {
      plugin = [
        "opencode-visual-cache@1.2.16"
        "opencode-subagent-statusline@1.2.0"
      ];
    };
  };

  #-----------------------------------------------------------------
  # MÓDULOS DE HOME MANAGER
  #-----------------------------------------------------------------
  # KITTY.CONF — Intencionalmente NO hacemos writable
  #-----------------------------------------------------------------
  # El builtin template de Noctalia para kitty ejecuta un apply.sh cuyo
  # comportamiento depende de si kitty.conf tiene permiso de escritura:
  #
  #   [ -w kitty.conf ] → kitty +kitten themes --reload-in=all noctalia
  #                       (cuelga: hace DNS a codeload.github.com, sin TTY)
  #
  #   [ ! -w kitty.conf ] → kitty +runpy "reload_conf_in_all_kitties()"
  #                       (funciona: usa el socket IPC de kitty en background)
  #
  # Como HM despliega kitty.conf como symlink al nix store (read-only),
  # apply.sh toma SIEMPRE la rama fallback que funciona. NO reemplazamos
  # el symlink con un archivo escribible — eso rompería la recarga.
  #
  # El wallpaper_changed hook en config.toml también envía SIGUSR1 (~2s
  # después del cambio) como respaldo adicional.
  #-----------------------------------------------------------------
  imports = [
    ../modules/niri.nix      # Niri + polkit + keyring.
    ../modules/firefox.nix   # Firefox desde unstable.
    ../modules/nvim.nix      # Neovim aislado con LSPs.
    ../modules/opencode.nix  # opencode (skills, plugins, MCPs).
    ../modules/noctalia.nix  # Noctalia: recortes, wallpaper y helpers.
    ../modules/stylix.nix    # Stylix: Firefox theme + GRUB/console (GTK a cargo de Noctalia).
    ../modules/sioyek.nix    # Sioyek: PDF reader con Qt/XCB (fix NVIDIA Wayland).

  ];
}
