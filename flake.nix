{
  description = "Flake NixOS + Home Manager minimal canvas";

  inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
		home-manager = {
			url = "github:nix-community/home-manager/release-25.11";
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
				nativeBuildInputs = with pkgs; [
					gcc       # compilador c 
					gnumake		# Make
          cmake     # CMake 
          pkg-config# Para que nix encuentre librerias.
					gdb	      # Debugger
					valgrind	# Analisis de memoria
					binutils	# Linker y herramientas binarias
				];
      	buildInputs = with pkgs; [
        	glfw      #Crea ventanas y maneja el input  
        	libglvnd  #Provee <GL/gl.h> y -lGL
        	glew      #Provee <GL/glew.h> Funciones modernas de OpenGl
        	glm       #Matematica para vectores. 
      	];
				shellHook = '' 
					echo "Entorno C activo (c-dev)" 
					export CFLAGS="-Wall -Wextra -O2"	
          export CXXFLAGS="-Wall -Wextra -O2" 
				'';
			};	
		};
	};
}

