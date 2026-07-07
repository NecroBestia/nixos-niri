{ pkgs, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Abre puertos para Steam Remote Play
    dedicatedServer.openFirewall = true; # Abre puertos para servidores dedicados Valve
    gamescopeSession.enable = true; # Micro-compositor para aislar juegos en Wayland

    # Instalación declarativa de Proton-GE recomendada por la Wiki
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Optimizador de rendimiento del sistema para juegos (Recomendado por la Wiki)
  programs.gamemode.enable = true;
}
