{pkgs, ...}: {
  systemd.user.services.wlsunset = {
    Unit = {
      Description = "Filtro luz azul (Manual)";
    };

    Service = {
      ExecStart = "${pkgs.wlsunset}/bin/wlsunset -t 3500 -T 6500";
      Restart = "always";
    };

    Install = {
      #WantedBy = [ "default.target" ]; # Opcional: quítalo si quieres que NUNCA inicie solo
    };
  };
systemd.user.services.polkit-gnome-authentication-agent-1 = {
  Unit = {
    Description = "polkit-gnome-authentication-agent-1";
    Wants = [ "graphical-session.target" ];
    After = [ "graphical-session.target" ];
  };
  Service = {
    Type = "simple";
    ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    Restart = "on-failure";
    RestartSec = 1;
    TimeoutStopSec = 10;
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};
}