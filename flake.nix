{
  description = "Flake NixOS + Home Manager minimal canvas";

  inputs = {
    # 1. Canal estable para el core del sistema y máxima estabilidad
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    # 2. Canal inestable para los paquetes que quieras tener en su última versión
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... } @ inputs:
    let
      system = "x86_64-linux";
      
      # 3. Paquetes estables con soporte para software privativo (ej. drivers, fuentes)
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; 
      };

      # 4. Paquetes inestables inicializados de la misma forma
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true; 
      };
    in {
      # Configuración NixOS
      nixosConfigurations = {
        # 5. Renombramos el host de "nixos" a "desktop" (Preparando la Parte 2)
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          # 6. Pasamos pkgs-unstable para que esté disponible en todo NixOS
          specialArgs = { inherit inputs pkgs-unstable; }; 
          modules = [
            ./nixos/configuration.nix
          ];
        };
      };

      # Home Manager
      homeConfigurations = {
        "necro" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # 7. Pasamos pkgs-unstable para que esté disponible en tu usuario
          extraSpecialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            ./home-manager/home.nix
          ];
        };
      };

      # 8. Los devShells globales de C y Python fueron eliminados.
      # Pasarán a ser Flakes individuales en las carpetas de tus proyectos.
    };
}