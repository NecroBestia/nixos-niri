#===================================================================
# SCRIPTS PERSONALIZADOS
#===================================================================
# Tres scripts auxiliares para el entorno Niri:
#
# 1. niri-clipboard:
#    Gestor del historial del portapapeles con interfaz fuzzel.
#    Muestra el historial de cliphist en un menú; permite copiar
#    un elemento o limpiar todo el historial.
#    Atajo: Mod+Ctrl+V (en binds.kdl).
#
# 2. niri-wallpaper:
#    Gestor de fondos de pantalla con dos capas:
#      - awww: Fondo de pantalla animado (transiciones suaves).
#      - swaybg: Fondo estático con blur (para el overview de Niri).
#    Selecciona un wallpaper aleatorio sin repetir hasta agotar
#    la lista. Genera una versión borrosa en caché para el overview.
#    Atajo: Mod+Ctrl+Shift+W (en binds.kdl).
#
# 3. spotify-startup:
#    Lanzador condicional de Spotify.
#    Si está instalado como Flatpak, lo ejecuta; si no, intenta
#    el binario nativo. Útil para entornos donde a veces se usa
#    Spotify vía Flatpak y otras veces vía sistema.
#    Se ejecuta al inicio (startup.kdl de Niri).
#===================================================================
{ pkgs, ... }: {
  #-----------------------------------------------------------------
  # niri-clipboard — Historial del Portapapeles
  #-----------------------------------------------------------------
  clipboard = pkgs.writeShellScriptBin "niri-clipboard" ''
    CLIPHIST="${pkgs.cliphist}/bin/cliphist"
    FUZZEL="${pkgs.fuzzel}/bin/fuzzel"
    WLCOPY="${pkgs.wl-clipboard}/bin/wl-copy"

    selection=$( (echo "wipe"; $CLIPHIST list) | $FUZZEL --dmenu --prompt "Clipboard: ")

    case "$selection" in
      "wipe")
        $CLIPHIST wipe
        ;;
      "")
        exit 0
        ;;
      *)
        echo "$selection" | $CLIPHIST decode | $WLCOPY
        ;;
    esac
  '';

  #-----------------------------------------------------------------
  # niri-wallpaper — Gestor de Fondos con Blur
  #-----------------------------------------------------------------
  niri-wallpaper = pkgs.writeShellScriptBin "niri-wallpaper" ''
    AWWW="${pkgs.awww}/bin/awww"
    MAGICK="${pkgs.imagemagick}/bin/magick"
    SWAYBG="${pkgs.swaybg}/bin/swaybg"
    FIND="${pkgs.findutils}/bin/find"
    SHUF="${pkgs.coreutils}/bin/shuf"
    MD5SUM="${pkgs.coreutils}/bin/md5sum"
    HEAD="${pkgs.coreutils}/bin/head"
    SED="${pkgs.gnused}/bin/sed"

    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    CACHE_BLUR_DIR="$HOME/.cache/niri-blur"
    OVERVIEW_WALL_TMP="$HOME/.cache/overview_wallpaper.jpg"
    PLAYLIST="$HOME/.cache/niri-wallpaper-playlist.txt"

    mkdir -p "$CACHE_BLUR_DIR"

    WALLPAPER=""

    while true; do
        if [ ! -s "$PLAYLIST" ]; then
            $FIND "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | $SHUF > "$PLAYLIST"
        fi

        WALLPAPER=$($HEAD -n 1 "$PLAYLIST")
        $SED -i '1d' "$PLAYLIST"

        if [ -f "$WALLPAPER" ]; then
            break
        fi
    done

    if [ -z "$WALLPAPER" ]; then
        exit 1
    fi

    WALL_HASH=$(echo "$WALLPAPER" | $MD5SUM | cut -d' ' -f1)
    CACHED_PHOTO="$CACHE_BLUR_DIR/$WALL_HASH.jpg"

    if [ ! -f "$CACHED_PHOTO" ]; then
        if ! $MAGICK "$WALLPAPER" -filter Triangle -resize 140% -blur 0x6 "$CACHED_PHOTO"; then
            exit 1
        fi
    fi

    cp "$CACHED_PHOTO" "$OVERVIEW_WALL_TMP"

    MAX_INTENTOS=10
    INTENTO=0
    until $AWWW query >/dev/null 2>&1; do
        if [ $INTENTO -ge $MAX_INTENTOS ]; then
            exit 1
        fi
        sleep 0.5
        INTENTO=$((INTENTO+1))
    done

    $AWWW img "$WALLPAPER" --transition-type fade

    pkill swaybg || true
    $SWAYBG -i "$OVERVIEW_WALL_TMP" -m fill &
  '';

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
}
