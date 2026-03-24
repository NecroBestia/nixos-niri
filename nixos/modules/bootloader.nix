{ pkgs, ... }: {
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true; # Esencial para detectar partición de Windows
      
      # Mantenemos la resolución para la consola
      gfxmodeEfi = "1920x1080"; 
      gfxpayloadEfi = "keep";
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  
  # Usamos ntfs3 que es nativo y más rápido que ntfs tradicional
  boot.supportedFilesystems = [ "ntfs3" ]; 
  boot.plymouth.enable = false; 

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  boot.kernelParams = [ 
    "quiet"
    "splash" 
    "loglevel=4" 
    "rd.systemd.show_status=false" 
    "rd.udev.log_level=3" 
    "udev.log_priority=3" 
    "nvidia_drm.fbdev=1"
    "nvidia_drm.modeset=1"
  ];

  boot.initrd.systemd.enable = true;
}