{
  security.rtkit.enable = true; 
  
  services.pipewire = {
    enable = true; 
    alsa.enable = true; 
    alsa.support32Bit = true;
    pulse.enable = true; 
    jack.enable = true; 
    wireplumber.enable = true;

    # Configuración balanceada - NO forzar quantum ultra-bajo
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;      # razonable para todo
        "default.clock.min-quantum" = 32;    # apps de audio pueden bajar
        "default.clock.max-quantum" = 8192;  # streaming puede subir
      };	
    };
  };
}