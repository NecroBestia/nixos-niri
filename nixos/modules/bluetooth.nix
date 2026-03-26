{config, ...}:
{
  hardware.bluetooth = {
    enable = true; 
    powerOnBoot = false; 
    settings = {
      General = {
        Experimental = true; 
        FastConnectable = true; 
      };
      Policy = {
        AutoEnable = true; 
      };
    };
  };
  services.blueman.enable = true; 
}

