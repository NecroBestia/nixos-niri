#===================================================================
# WLOGOUT — Menú de Apagado/Reinicio/Suspender
#===================================================================
# Wlogout es un menú de acciones del sistema para Wayland.
# Proporciona botones para:
#   - Apagar (systemctl poweroff)
#   - Reiniciar (systemctl reboot)
#   - Suspender (systemctl suspend)
#   - Hibernar (systemctl hibernate)
#   - Bloquear (swaylock)
#   - Cerrar sesión (niri msg action quit)
#
# Atajo: Super+Alt+L (definido en binds.kdl de Niri).
# Icono en Waybar: ⏻ (custom/power) abre wlogout al hacer clic.
#===================================================================
{ lib, ... }: {
  programs.wlogout.enable = true;

  home.file."."config/wlogout/icons" = lib.mkForce {
    source = ../config/wlogout/icons;
    recursive = true;
  };

  home.file."."config/wlogout/layout".source    = lib.mkForce ../config/wlogout/layout;
  home.file."."config/wlogout/style.css".source  = lib.mkForce ../config/wlogout/style.css;
}
