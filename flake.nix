#===================================================================
# FLATE PRINCIPAL — NixOS + Home Manager
#===================================================================
# Este flake gestiona la configuración completa de dos máquinas:
#   - desktop: PC de sobremesa con GPU NVIDIA y discos NTFS.
#   - notebook: ThinkPad con optimizaciones de batería y Intel.
#
# ESTRUCTURA:
#   nixos/          → Configuración del sistema (NixOS).
#   home-manager/   → Configuración de usuario (Home Manager).
#   ├── hosts/      → Por máquina (desktop, notebook).
#   ├── shared/     → Común a ambas máquinas.
#   ├── modules/    → Módulos funcionales (niri, firefox, etc.).
#   └── config/     → Archivos dotfiles (waybar, niri, kitty...).
#===================================================================
{
  description = "Flake NixOS + Home Manager (Desktop & Notebook)";

  inputs = {
    # Rama ESTABLE de NixOS (usada como base del sistema).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Rama UNSTABLE para paquetes que necesitan versión reciente
    # (niri, neovim, krita, obsidian, vscodium, etc.).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager sincronizado con la rama estable de nixpkgs.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pin del kernel a una revisión específica de nixpkgs.
    # MOTIVO: La GPU NVIDIA serie 570 requiere un kernel específico
    # (6.18.13) para mantener compatibilidad con el driver.
    # No actualizar sin verificar compatibilidad.
    nixpkgs-kernel.url = "github:NixOS/nixpkgs/d756e131ad4cc63b6e0dde373fbae0ce4ce9d683";

    # Skill NixOS completo con referencias oficiales (SKILL.md + docs).
    nixos-skill = {
      url = "github:marceloeatworld/nixos-ai-skill";
      flake = false;
    };

    # Skills de Vercel (web-design-guidelines, composition-patterns, etc).
    vercel-skills = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-kernel, home-manager, ... } @ inputs:
    let
      # Arquitectura objetivo (x86_64).
      system = "x86_64-linux";

      # nixpkgs ESTABLE con unfree habilitado.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # nixpkgs UNSTABLE con unfree habilitado.
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      #-----------------------------------------------------------------
      # CONFIGURACIONES NixOS
      #-----------------------------------------------------------------
      # Cada entrada importa un archivo host + hardware + shared.
      # Los specialArgs pasan inputs y pkgs-unstable a TODOS los módulos.
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            ./nixos/hosts/desktop/configuration.nix
          ];
        };

        notebook = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            ./nixos/hosts/notebook/configuration.nix
          ];
        };
      };

      #-----------------------------------------------------------------
      # CONFIGURACIONES Home Manager
      #-----------------------------------------------------------------
      # Siguen el patrón "necro@hostname" para que el alias
      # "hm-switch" funcione con $HOSTNAME.
      homeConfigurations = {
        "necro@desktop" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            ./home-manager/hosts/desktop/default.nix
          ];
        };

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
