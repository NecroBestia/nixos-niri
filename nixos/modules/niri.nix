#===================================================================
# NIRI — Compositor Wayland (System-Level)
#===================================================================
# Niri es un compositor Wayland basado en tiles con scroll infinito.
# A nivel de sistema, este módulo activa Niri como sesión disponible
# y proporciona xwayland-satellite (servidor XWayland independiente).
#
# La configuración del USUARIO (keybinds, layouts, etc.) está en
# home-manager/modules/niri.nix y los dotfiles en config/niri/.
#===================================================================
{ pkgs, pkgs-unstable, ... }: {
  programs.niri = {
    enable = true;
    package = pkgs-unstable.niri;  # Niri desde unstable (última versión).
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite  # XWayland independiente (mejor rendimiento en apps X11).
  ];
}
