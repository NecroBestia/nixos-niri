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
#   ├── modules/    → Módulos funcionales (niri, firefox, opencode...).
#   │   ├── ai-inputs.nix  → Inputs de skills IA (importado abajo).
#   │   └── opencode.nix   → Config de opencode (skills, plugins, MCP).
#   └── config/     → Archivos dotfiles (waybar, niri, kitty...).
#===================================================================
{
  description = "Flake NixOS + Home Manager (Desktop & Notebook)";

  #===================================================================
  # INPUTS DEL SISTEMA
  #===================================================================
  # Estos inputs son la base del sistema operativo y no deben
  # modificarse sin verificar compatibilidad.
  #===================================================================
  inputs = {
    # Rama ESTABLE de NixOS (usada como base del sistema).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Rama UNSTABLE para paquetes que necesitan versión reciente
    # (niri, neovim, krita, obsidian, vscodium, opencode, etc.).
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

    # Noctalia v5 — Wayland shell nativo (bar, launcher, notifs, wallpaper, etc.).
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #===================================================================
    # INPUTS DE SKILLS IA
    #===================================================================
    # Ver home-manager/modules/ai-inputs.nix para documentación
    # detallada de cada input. Los inputs deben definirse aquí
    # porque el schema de flake no permite importarlos.
    #===================================================================

    # NixOS — Skill oficial con documentación completa del sistema.
    nixos-skill = {
      url = "github:marceloeatworld/nixos-ai-skill";
      flake = false;
    };

    # Vercel — Skills de diseño web y buenas prácticas React/Next.js.
    vercel-skills = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };

    # Anthropic — Skills oficiales de desarrollo (MCP, testing, frontend).
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    # opencode-kit — Skills UI/UX adicionales.
    opencode-kit = {
      url = "github:skeletorflet/opencode-kit";
      flake = false;
    };

    # OPENCODE-6-2026 — Skills de diseño UI/UX.
    opencode-6-2026 = {
      url = "github:mohamednaeem92-max/OPENCODE-6-2026";
      flake = false;
    };

    # TuTiendaWeb — Skills de revisión de diseño UI/UX.
    tutiendaweb-public = {
      url = "github:MaxiAramayo/TuTiendaWeb-public";
      flake = false;
    };

    # oh-my-opencode — Skills de frontend compartidas.
    oh-my-opencode = {
      url = "github:code-yeongyu/oh-my-opencode";
      flake = false;
    };

    # TypeUI — Skills de diseño con paletas y layouts.
    typeui = {
      url = "github:bergside/typeui";
      flake = false;
    };

    # stop-slop — Elimina clichés y marcas de IA de textos.
    stop-slop = {
      url = "github:hardikpandya/stop-slop";
      flake = false;
    };

    # Composio — 1000+ integraciones SaaS como skill + MCP.
    composio-skills = {
      url = "github:composio-community/opencode-skills";
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
