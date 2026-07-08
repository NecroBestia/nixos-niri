#===================================================================
# FIREWALL — nftables + OpenSnitch
#===================================================================
# nftables: Firewall moderno (reemplazo de iptables).
# OpenSnitch: Firewall interactivo por aplicación (como Little Snitch).
#
# LO QUE SIEMPRE ESTÁ ACTIVO (independientemente de opensnitch):
#   - nftables como backend de firewall.
#   - DNS Quad9 (9.9.9.9) para resolución segura y privada.
#   - Firewall básico:
#       * Ping permitido (ICMP echo).
#       * Puerto 22/TCP abierto (SSH).
#       * Interfaz virbr0 confiable (VMs de libvirt).
#   - Hardening de red (sysctl):
#       * rp_filter = 1: Filtro de ruta inversa (anti-spoofing).
#       * icmp_echo_ignore_broadcasts = 1: Ignora pings de broadcast.
#       * icmp_ignore_bogus_error_responses = 1: Ignora ICMP falsos.
#       * tcp_syncookies = 1: Protección SYN Flood (DDoS).
#       * ip_forward = 1: Reenvío de paquetes (necesario para VMs).
#
# OPENS NITCH (TOGGLEABLE):
#   - opensnitch.enable = lib.mkDefault true (overridable por host).
#   - DefaultAction = "deny": Bloquea todo el tráfico saliente no
#     explícitamente permitido.
#   - LogLevel = 2: Logging de conexiones bloqueadas.
#
# Los hosts pueden desactivar opensnitch con:
#   services.opensnitch.enable = false;
# Útil en portátiles que cambian de red frecuentemente.
#===================================================================
{ config, pkgs, pkgs-unstable, lib, ... }: {
  networking.nftables.enable = true;
  networking.nameservers = [ "9.9.9.9" ];

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [22];
    trustedInterfaces = [ "virbr0" ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.ip_forward" = 1;
  };

  services.opensnitch = {
    enable = lib.mkDefault true;
    package = pkgs-unstable.opensnitch;
    settings = {
      DefaultAction = "deny";
      LogLevel = 2;
    };
  };

  environment.systemPackages = lib.mkIf config.services.opensnitch.enable (with pkgs-unstable; [ opensnitch-ui ]);
}
