{pkgs,...}:{
	# Se activa docker
	virtualisation.docker = {
		enable = true; 
		rootless = {
			enable = true;
			setSocketVariable = true; 
		};
		daemon.settings = {
			data-root = "/home/Docker"; 
		};
	};
	environment.systemPackages = [ pkgs.docker-compose];
	
}
