#===================================================================
# SCRIPTS PERSONALIZADOS
#===================================================================
# Cuatro scripts auxiliares para el entorno Niri:
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
#
# 4. niri-symlinks:
#    Crea los enlaces simbólicos necesarios para el entorno.
#    Actualmente asegura que ~/Pictures/Wallpapers apunte a
#    ~/nixFlake/wallpapers. Se ejecuta al inicio (startup.kdl).
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
  # niri-wallpaper — Gestor de Fondos (awww + swaybg blur)
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

    # ──────────────────────────────────────────────
    # 1. ESPERAR A QUE EXISTA EL DIRECTORIO
    #    Niri lanza niri-symlinks y niri-wallpaper
    #    en paralelo. Si el symlink no existe aún,
    #    el script espera hasta 5s.
    # ──────────────────────────────────────────────
    if [ ! -d "$WALLPAPER_DIR" ]; then
        for i in 1 2 3 4 5 6 7 8 9 10; do
            [ -d "$WALLPAPER_DIR" ] && break
            sleep 0.5
        done
    fi

    # Fallback: ruta directa si el symlink falla
    if [ ! -d "$WALLPAPER_DIR" ]; then
        WALLPAPER_DIR="$HOME/nixFlake/wallpapers"
    fi

    # ──────────────────────────────────────────────
    # 2. ELEGIR WALLPAPER ALEATORIO
    #    find -L es clave: sigue symlinks, si no
    #    no encuentra archivos en el directorio.
    # ──────────────────────────────────────────────
    WALLPAPER=""
    while true; do
        if [ ! -s "$PLAYLIST" ]; then
            $FIND -L "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | $SHUF > "$PLAYLIST"
        fi

        WALLPAPER=$($HEAD -n 1 "$PLAYLIST")
        $SED -i '1d' "$PLAYLIST"

        if [ -f "$WALLPAPER" ]; then
            break
        fi
    done

    if [ -z "$WALLPAPER" ]; then
        notify-send "niri-wallpaper" "No hay wallpapers en $WALLPAPER_DIR" -t 5000
        exit 1
    fi

    # ──────────────────────────────────────────────
    # 3. GENERAR VERSIÓN BORROSA EN CACHÉ
    #    Para el overview de niri (swaybg la muestra)
    # ──────────────────────────────────────────────
    WALL_HASH=$(echo "$WALLPAPER" | $MD5SUM | cut -d' ' -f1)
    CACHED_PHOTO="$CACHE_BLUR_DIR/$WALL_HASH.jpg"

    if [ ! -f "$CACHED_PHOTO" ]; then
        if ! $MAGICK "$WALLPAPER" -filter Triangle -resize 140% -blur 0x6 "$CACHED_PHOTO"; then
            notify-send "niri-wallpaper" "Error generando blur" -t 3000
            exit 1
        fi
    fi

    cp "$CACHED_PHOTO" "$OVERVIEW_WALL_TMP"

    # ──────────────────────────────────────────────
    # 4. ESPERAR A QUE awww-daemon ESTÉ LISTO
    # ──────────────────────────────────────────────
    MAX_INTENTOS=10
    INTENTO=0
    until $AWWW query >/dev/null 2>&1; do
        if [ $INTENTO -ge $MAX_INTENTOS ]; then
            notify-send "niri-wallpaper" "awww-daemon no responde" -t 5000
            exit 1
        fi
        sleep 0.5
        INTENTO=$((INTENTO+1))
    done

    # ──────────────────────────────────────────────
    # 5. ESTABLECER WALLPAPER
    #    awww: transición animada (fade).
    #    swaybg: fondo estático blur para overview.
    #    swaybg arranca DESPUÉS, así que el blur
    #    es lo que se muestra en todo momento.
    # ──────────────────────────────────────────────
    $AWWW img "$WALLPAPER" --transition-type fade

    pkill swaybg 2>/dev/null || true
    $SWAYBG -i "$OVERVIEW_WALL_TMP" -m fill &

    notify-send "Wallpaper" " $(basename "$WALLPAPER")" -t 3000
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

  #-----------------------------------------------------------------
  # niri-symlinks — Crea enlaces simbólicos del entorno
  #-----------------------------------------------------------------
  # Asegura que los directorios necesarios para los scripts del
  # entorno tengan sus enlaces simbólicos en su lugar.
  #
  # Actualmente:
  #   ~/Pictures/Wallpapers → ~/nixFlake/wallpapers/
  #     (Necesario para niri-wallpaper y awww.)
  #-----------------------------------------------------------------
  niri-symlinks = pkgs.writeShellScriptBin "niri-symlinks" ''
    FLAKE_DIR="$HOME/nixFlake"

    # Enlace: Wallpapers
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
