{
  description = "Flake NixOS + Home Manager (Desktop & Notebook)";

inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # --- version kernel 6.18.13 --- 
    nixpkgs-kernel.url = "github:NixOS/nixpkgs/d756e131ad4cc63b6e0dde373fbae0ce4ce9d683";
};

  outputs = { self, nixpkgs, nixpkgs-unstable,nixpkgs-kernel, home-manager, ... } @ inputs:
    let
      system = "x86_64-linux";
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; 
      };

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true; 
      };
    in {
      # --- CONFIGURACIONES DEL SISTEMA (NixOS) ---
      nixosConfigurations = {
        
        # 1. PC de Sobremesa
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable; }; 
          modules = [
            ./nixos/hosts/desktop/configuration.nix 
          ];
        };

        # 2. ThinkPad
        notebook = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable; }; 
          modules = [
            ./nixos/hosts/notebook/configuration.nix 
          ];
        };
      };

      # --- CONFIGURACIONES DE USUARIO (Home Manager) ---
      homeConfigurations = {
        
        # 1. Usuario para el Sobremesa
        "necro@desktop" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            ./home-manager/hosts/desktop/default.nix
          ];
        };

        # 2. Usuario para el ThinkPad
        "necro@notebook" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            ./home-manager/hosts/notebook/default.nix
          ];
        };
      };
    };
}
