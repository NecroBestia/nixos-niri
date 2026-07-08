#===================================================================
# WLSUNSET — Filtro de Luz Azul
#===================================================================
# wlsunset ajusta la temperatura de color de la pantalla según
# la hora del día (reduce luz azul por la noche).
#
# CONFIGURACIÓN:
#   -t 3500 (day): Temperatura de color durante el día.
#   -T 3550 (night): Temperatura de color durante la noche.
#   * Diferencia mínima (50K) para un efecto siempre cálido.
#
# COMPORTAMIENTO ACTUAL:
#   - Timer: Inicia el servicio automáticamente a las 10 PM.
#   - Toggle manual: Desde Waybar (icono ☯/☀) se puede encender
#     o apagar en cualquier momento.
#   - Restart = "on-failure": Reinicia si falla, pero no si se
#     detiene manualmente (waybar toggle).
#
# El timer se instala con WantedBy = default.target, así que
# arranca al iniciar sesión. A las 10 PM ejecuta wlsunset.
#===================================================================
{ pkgs, ... }: {
  systemd.user.services.wlsunset = {
    Unit = {
      Description = "Filtro luz azul";
    };

    Service = {
      ExecStart = "${pkgs.wlsunset}/bin/wlsunset -t 3500 -T 3550";
      Restart = "on-failure";
    };

    Install = {};
  };

  systemd.user.timers.wlsunset = {
    Unit = {
      Description = "Iniciar wlsunset a las 10 PM";
    };

    Timer = {
      OnCalendar = "*-*-* 22:00:00";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
