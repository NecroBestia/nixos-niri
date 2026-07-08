#===================================================================
# DISPLAY MANAGER — SDDM
#===================================================================
# SDDM (Simple Desktop Display Manager) con tema sddm-astronaut.
# Es el gestor de inicio de sesión gráfico para Wayland.
#
#   - xserver.enable = true: Necesario para SDDM (aunque corremos
#     Wayland, SDDM arranca en X11 y luego ejecuta Niri).
#   - InputMethod = "": Desactiva el teclado virtual en pantalla
#     (innecesario en PCs físicas).
#   - extraPackages: Dependencias del tema sddm-astronaut
#     (qtmultimedia, qtsvg, qt5compat).
#===================================================================
{ pkgs, ... }: {
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "latam";
        variant = "";
      };
    };
    displayManager.sddm = {
      enable = true;
      theme = "sddm-astronaut-theme";
      settings = {
        General = {
          InputMethod = "";
        };
      };
      extraPackages = with pkgs; [
        sddm-astronaut
        kdePackages.qtmultimedia
        kdePackages.qtsvg
        kdePackages.qt5compat
      ];
    };
  };
}
