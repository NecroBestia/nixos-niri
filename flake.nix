{
  description = "Flake NixOS + Home Manager minimal canvas";

  inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
	home-manager.url = "github:nix-community/home-manager/release-25.05";
	home-manager.inputs.nixpkgs.follows = "nixpkgs"; 
	
  };

  outputs = { self, nixpkgs, home-manager,... }: 
      let
	system = "x86_64-linux";
        
      in {
        # Paquetes simples de ejemplo
        

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
          		pkgs = import nixpkgs {inherit system;};
			modules  = [
				./home-manager/home.nix

				        
				];
				
			};
		};
      
	};
}

