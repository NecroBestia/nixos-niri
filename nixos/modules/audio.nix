{
	#services.pulseaudio.enable = false;
	#hardware.pulseaudio.enable = false; 
	security.rtkit.enable = true; 
	
	services.pipewire = {
		enable = true; 
		alsa.enable = true; 
		alsa.support32Bit = true;
		pulse.enable = true; 
		jack.enable = true; 
		wireplumber.enable = true;

		# Configuracion baja latencia 
		extraConfig.pipewire."92-low-latency" = {
			"context.properties" = {
				"default.clock.rate" = 48000;
				"default.clock.quantum" = 32; 
				"default.clock.min-quantum" = 32;
				"dafault.clock.max-quantum" = 32; 
			};	
		};
		#Para que otras aplicaciones puedan interactuar con el driver de audio
		extraConfig.pipewire-pulse."92-low-latency" = {
			context.modules  = [
			{
				name = "libpipewire-module-protocol-pulse" ;
				args = {
					pulse.min.req = "32/48000";
					pulse.default.req = "32/48000";
					pulse.max.req = "32/48000";
					pulse.min.quantum = "32/48000";
					pulse.max.quantum = "32/48000"; 
				};	
			}
			];		
			stream.properties = {
				node.latency = "32/48000";
				resample.quality = 1;
			};
		 };
		socketActivation = true;

	};
 
}
