#===================================================================
# SCRIPTS PERSONALIZADOS
#===================================================================
# Dos scripts auxiliares:
#
# 1. spotify-startup:
#    Lanzador condicional de Spotify.
#    Si está instalado como Flatpak, lo ejecuta; si no, intenta
#    el binario nativo. Se ejecuta al inicio (startup.kdl de Niri).
#
# 2. niri-symlinks:
#    Crea los enlaces simbólicos necesarios para el entorno.
#    Actualmente asegura que ~/Pictures/Wallpapers apunte a
#    ~/nixFlake/wallpapers. Se ejecuta al inicio (startup.kdl).
#===================================================================
{ pkgs, ... }: {
  #-----------------------------------------------------------------
  # spotify-startup — Lanzador Condicional de Spotify
  #-----------------------------------------------------------------
  spotify-startup = pkgs.writeShellScriptBin "spotify-startup" ''
    if flatpak list | grep -qi spotify; then
      flatpak run com.spotify.Client
    else
      spotify
    fi
  '';

  #-----------------------------------------------------------------
  # niri-symlinks — Crea enlaces simbólicos del entorno
  #-----------------------------------------------------------------
  niri-symlinks = pkgs.writeShellScriptBin "niri-symlinks" ''
    FLAKE_DIR="$HOME/nixFlake"

    TARGET="$FLAKE_DIR/wallpapers"
    LINK="$HOME/Pictures/Wallpapers"

    if [ ! -d "$TARGET" ]; then
        echo "niri-symlinks: ERROR — $TARGET no existe"
        exit 1
    fi

    if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$TARGET" ]; then
        exit 0
    fi

    if [ -e "$LINK" ]; then
        echo "niri-symlinks: $LINK existe pero no es el symlink esperado, respaldando..."
        backup="$LINK.backup.$(date +%s)"
        mv "$LINK" "$backup"
    fi

    ln -s "$TARGET" "$LINK"
    echo "niri-symlinks: creado $LINK → $TARGET"
  '';
}
