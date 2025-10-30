{ pkgs, ...} : {
	programs.firefox = 
	{
		enable = true;
		package = with pkgs; 
		firefox.override { 
			nativeMessagingHosts = [ tridactyl-native ];
		};
	};

}
