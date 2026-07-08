#===================================================================
# BLUETOOTH — Hardware + Blueman
#===================================================================
# Configura el hardware Bluetooth del sistema:
#   - Experimental: Habilita características nuevas del kernel
#     (como LE Audio, si el hardware lo soporta).
#   - FastConnectable: Responde a solicitudes de emparejamiento
#     más rápido (reduce delay de conexión).
#   - AutoEnable: Enciende el adaptador cuando se solicita
#     (sin necesidad de activación manual).
#
# powerOnBoot = false: No enciende Bluetooth al arrancar.
# (Ahorra batería en notebooks; se activa desde Waybar o CLI).
#===================================================================
{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  services.blueman.enable = true;  # Applet GUI para gestión Bluetooth.
}
