{pkgs, ...}: {
  systemd.user.services.wlsunset = {
    Unit = {
      Description = "Filtro luz azul (Manual)";
    };

    Service = {
      ExecStart = "${pkgs.wlsunset}/bin/wlsunset -t 3500 -T 3550";
      Restart = "always";
    };

    Install = {
      #WantedBy = [ "default.target" ]; # Opcional: quítalo si quieres que NUNCA inicie solo
    };
  };

}
