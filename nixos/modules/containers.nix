#===================================================================
# CONTENEDORES — Podman / Docker (TOGGLEABLE)
#===================================================================
# Permite elegir entre Podman o Docker como runtime de contenedores.
# TOGGLEABLE via programs.containers.enable.
#
# Podman (default): Sin daemon, rootless, docker-compat.
# Docker: Alternativa tradicional con daemon systemd.
#
# USO:
#   programs.containers.enable = false;  # Desactiva contenedores.
#   programs.containers.backend = "docker";  # Cambia a Docker.
#===================================================================
{ config, lib, pkgs, ... }: {
  options.programs.containers = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable container runtime";
    };
    backend = lib.mkOption {
      type = lib.types.enum [ "podman" "docker" ];
      default = "podman";
      description = "Container runtime backend";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.programs.containers.enable && config.programs.containers.backend == "podman") {
      virtualisation.containers.enable = true;
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      environment.systemPackages = with pkgs; [
        dive podman-tui docker-compose podman-compose
      ];
    })
    (lib.mkIf (config.programs.containers.enable && config.programs.containers.backend == "docker") {
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
      environment.systemPackages = [ pkgs.docker-compose ];
    })
  ];
}
