{
  description = "Flake NixOS + Home Manager minimal canvas";

  inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		home-manager = {
			url = "github:nix-community/home-manager/release-25.05";
			inputs.nixpkgs.follows = "nixpkgs"; 
		};
		
	}; 
	
  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
      let
	system = "x86_64-linux";
        pkgs = import nixpkgs {inherit system;};
      in {
     	# Configuración NixOS
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
		./nixos/configuration.nix
          ];
        };

        # Home Manager
        homeConfigurations={
	"necro" =  home-manager.lib.homeManagerConfiguration {
          		inherit pkgs;
			extraSpecialArgs = {inherit inputs;}; 
			modules  = [
					./home-manager/home.nix
							        
				];
				
			};
		};
      
	
	devShells = {
			${system}.c-dev = pkgs.mkShell {
				pname = "c-dev-shell"; 
				buildInputs = with pkgs; [
					gcc		#compilador c 
					gnumake		#make 
					gdb		#cmake
					valgrind	#debugger
					binutils	#analisis de memoria 
				];

				shellHook = '' 
					echo "Entorno C activo (c-dev)" 
					export CFLAGS="-Wall -Wextra -02"	

				'';
			};	
		};
	};
}

