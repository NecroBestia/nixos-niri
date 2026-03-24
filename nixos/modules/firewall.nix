{pkgs,  ...}:
{
  networking.nftables.enable = true; 
  #DNS mas segura y privada. 
  networking.nameservers = [ "9.9.9.9" ];
  #Configuracion Firewall
  networking.firewall = {
    enable = true; 
    allowPing = true;
    allowedTCPPorts = [22];
  };
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    # Ignorar pings de broadcast (Evita ataques Smurf y ruido en la red)
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Protección contra mensajes de error ICMP falsos
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Protección contra ataques SYN Flood (DDoS básico)
    "net.ipv4.tcp_syncookies" = 1;
    # Deshabilitar el reenvío de paquetes
    "net.ipv4.ip_forward" = 0;
  };
  #opensnitch; permite gestionar conexiones de programas al internet y viceversa. 
  services.opensnitch = {
    enable = true; 
    settings = {
      DefaultAction = "deny"; 
      LogLevel = 2;
    };
  };
  environment.systemPackages = with pkgs; [opensnitch-ui];
}