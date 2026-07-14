#===================================================================
# SHARED — Configuración Común a Ambos Hosts
#===================================================================
# Este archivo importa todos los módulos que aplican a desktop y
# notebook por igual. Cada host puede override opciones individuales
# (ej: vm.libvirtd = false en notebook, opensnitch = false en notebook).
# Tambíén define configuraciones base como fonts, nix, seguridad, etc.
#===================================================================
{ config, pkgs, lib, ... }: {
  #-----------------------------------------------------------------
  # MÓDULOS IMPORTADOS (Aplican a ambos hosts)
  #-----------------------------------------------------------------
  # Cada módulo es un archivo independiente en nixos/modules/.
  # Algunos módulos tienen opciones toggle (vm.libvirtd,
  # services.opensnitch.enable) que cada host puede override.
  imports = [
    ../../modules/bootloader.nix       # GRUB + EFI + dual-boot.
    ../../modules/audio.nix            # PipeWire + WirePlumber + baja latencia.
    ../../modules/fileManager.nix      # Nautilus + GVFS + UDisks2.
    ../../modules/locale.nix           # Zona horaria + idioma.
    ../../modules/bluetooth.nix        # Bluetooth + Blueman.
    ../../modules/niri.nix             # Niri compositor (system-wide).
    ../../modules/displayManager.nix   # SDDM + tema astronauta.
    ../../modules/services.nix         # SSH, Syncthing, Flatpak, portales XDG.
    ../../modules/containers.nix       # Podman (runtime de contenedores).
    ../../modules/firewall.nix         # Firewall nftables + opensnitch.
    ../../modules/vm.nix               # Virtualización libvirtd (toggleable).
    ../../modules/stylix.nix           # Stylix: tema GRUB/consola desde wallpaper.
  ];

  #-----------------------------------------------------------------
  # CONSOLA
  #-----------------------------------------------------------------
  console.keyMap = "la-latin1";

  networking.networkmanager.enable = true;

  #-----------------------------------------------------------------
  # USUARIO
  #-----------------------------------------------------------------
  users.users.necro = {
    isNormalUser = true;
    description = "necro";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "storage" ]
      ++ lib.optionals (config.programs.containers.backend == "docker") [ "docker" ];
  };

  #-----------------------------------------------------------------
  # FUENTES DEL SISTEMA
  #-----------------------------------------------------------------
  # Incluye Nerd Fonts para la terminal y Waybar, y Noto CJK para
  # caracteres chinos, japoneses y coreanos en documentos/PDF.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];
  fonts.fontDir.enable = true;

  #-----------------------------------------------------------------
  # GESTOR DE PAQUETES NIX
  #-----------------------------------------------------------------
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];  # Flakes habilitado.
      auto-optimise-store = true;     # Deduplica el store automáticamente.
      download-buffer-size = 524288000; # 500 MB buffer de descarga.
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
    };
    gc = {
      automatic = true;               # Limpieza automática diaria.
      dates = "daily";
      options = "--delete-older-than 10d";  # Borra generaciones >10 días.
    };
  };

  nixpkgs.config.allowUnfree = true;  # Paquetes privativos.

  #-----------------------------------------------------------------
  # GSETTINGS — Schemas para GLib (necesario para thumbnails, íconos)
  #-----------------------------------------------------------------
  environment.pathsToLink = [ "/share/gsettings-schemas" ];

  #-----------------------------------------------------------------
  # SEGURIDAD
  #-----------------------------------------------------------------
  security = {
    sudo.enable = true;      # Gestión de permisos con sudo.
    apparmor.enable = true;  # Control de acceso obligatorio (MAC).
    polkit.enable = true;    # Autorización para servicios del sistema.
  };

  #-----------------------------------------------------------------
  # PAQUETES BASE DEL SISTEMA
  #-----------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    vim            # Editor de respaldo.
    wget           # Descarga por HTTP.
    git            # Control de versiones.
    home-manager   # Gestor de config de usuario.
    sddm-astronaut # Tema para el gestor de sesión SDDM.
    htop           # Monitor de procesos interactivo.
    papirus-icon-theme  # Iconos para el escritorio.
    glib           # gsettings CLI + schemas (necesario para thumbnails, íconos de carpeta).
  ];

  xdg.icons.enable = true;

  # Desactiva el gestor de sesión Xterm por defecto.
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.excludePackages = [ pkgs.xterm ];

}
