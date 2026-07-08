#===================================================================
# CONTENEDORES — Podman
#===================================================================
# Podman es un motor de contenedores sin daemon (rootless por defecto).
# A diferencia de Docker, no requiere un proceso en segundo plano,
# lo que mejora la seguridad y el aislamiento.
#
#   - dockerCompat = true: Proporciona el comando "docker" como
#     alias de Podman. Cualquier script o herramienta que use
#     "docker" funcionará sin cambios.
#   - dns_enabled: Permite que los contenedores se resuelvan entre
#     sí por nombre (esencial para docker-compose/podman-compose).
#
# HERRAMIENTAS INCLUIDAS:
#   - dive: Inspecciona capas de imágenes Docker/Podman.
#   - podman-tui: Interfaz TUI para gestionar contenedores.
#   - docker-compose: Orquestación de múltiples contenedores.
#   - podman-compose: Alternativa nativa de Podman.
#
# TRADEOFF: Podman con dockerCompat NO es 100% compatible con
# todas las herramientas Docker (ej: algunas integraciones de
# IDE pueden fallar). Si se necesita compatibilidad total,
# cambiar a virtualisation.docker.enable = true.
#===================================================================
{ pkgs, ... }: {
  virtualisation.containers.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    dive
    podman-tui
    docker-compose
    podman-compose
  ];
}
