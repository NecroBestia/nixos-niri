{ pkgs, ... }: {
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true; # Esencial para detectar partición de Windows
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  
  # Usamos ntfs3 que es nativo y más rápido que ntfs tradicional
  boot.supportedFilesystems = [ "ntfs" "ntfs3" ]; 
  boot.plymouth.enable = false; 


  #boot.kernelParams = [ 
    #"quiet"
    #"splash" 
    #"loglevel=4" 
    #"rd.systemd.show_status=false" 
    #"rd.udev.log_level=3" 
    #"udev.log_priority=3" 
    #  ];

  boot.initrd.systemd.enable = true;
}
