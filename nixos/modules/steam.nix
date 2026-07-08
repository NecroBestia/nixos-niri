#===================================================================
# STEAM — Gaming
#===================================================================
# Configuración completa de Steam para juegos en Wayland:
#
#   - gamescopeSession.enable = true: Micro-compositor que aísla
#     cada juego en su propia sesión Wayland (evita problemas de
#     escalado, VSync, y compatibilidad con X11).
#   - remotePlay.openFirewall: Puertos abiertos para Steam Link.
#   - extraCompatPackages: Proton-GE (Glorious Eggroll) para
#     compatibilidad mejorada con juegos de Windows.
#
# Gamemode: Optimizador de rendimiento del sistema (CPU governor,
# prioridad de E/S, etc.) activado automáticamente al iniciar juegos.
#===================================================================
{ pkgs, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode.enable = true;
}
