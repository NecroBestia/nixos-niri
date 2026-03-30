{ pkgs, pkgs-unstable, ...} : {
	programs.firefox = 
	{
		enable = true;
#		package = with pkgs; 
#		firefox.override { 
#			nativeMessagingHosts = [ tridactyl-native ];
#		};
		package = pkgs-unstable.firefox;
	};


}
