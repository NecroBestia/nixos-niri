{ pkgs, ... }: {

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
      
      # Mantenemos esto para que la consola de texto tenga buena resolución
      gfxmodeEfi = "1920x1080"; 
      gfxpayloadEfi = "keep";
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.supportedFilesystems = [ "ntfs" ];
  boot.plymouth.enable=false; 
  # Módulos tempranos (Nvidia necesita esto sí o sí)
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  boot.kernelParams = [ 
    "quiet"
    "splash" 
    "loglevel=4" 
    "rd.systemd.show_status=false" 
    "rd.udev.log_level=3" 
    "udev.log_priority=3" 
    "nvidia_drm.fbdev=1"
    "nvidia-drm.modset=1"
  ];
  # boot.initrd.systemd.enable = true; 
  # Nota: Puedes dejar esto en true o false. 
  # En true es más moderno, pero si algo falla en el arranque, 
  # a veces ponerlo en false ayuda a debuggear initrd clásico. 
  # Por ahora, déjalo así si te funcionaba antes, o bórralo si quieres un boot más simple.
  boot.initrd.systemd.enable = true;
}
