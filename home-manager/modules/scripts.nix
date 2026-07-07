{ pkgs, ... }:
{
  clipboard = pkgs.writeShellScriptBin "niri-clipboard" ''
    # Usamos rutas absolutas para que el script sea independiente del sistema
    CLIPHIST="${pkgs.cliphist}/bin/cliphist"
    FUZZEL="${pkgs.fuzzel}/bin/fuzzel"
    WLCOPY="${pkgs.wl-clipboard}/bin/wl-copy"

    # --- Ejecución de la interfaz ---
    # Concatenamos la opción de limpieza con la lista actual del historial
    # El resultado se guarda en la variable 'selection'
    selection=$( (echo "wipe"; $CLIPHIST list) | $FUZZEL --dmenu --prompt "Clipboard: ")

    # --- Lógica de procesamiento ---
    case "$selection" in
      "wipe")
        # El usuario eligió borrar todo el historial
        $CLIPHIST wipe
        ;;
      "")
        # El usuario cerró el menú sin elegir nada (Esc)
        exit 0
        ;;
      *)
        # El usuario seleccionó un elemento para copiar
        echo "$selection" | $CLIPHIST decode | $WLCOPY
        ;;
    esac
  '';
  niri-wallpaper = pkgs.writeShellScriptBin "niri-wallpaper" ''
    # Binarios declarativos
    AWWW="${pkgs.awww}/bin/awww"
    MAGICK="${pkgs.imagemagick}/bin/magick"
    SWAYBG="${pkgs.swaybg}/bin/swaybg"
    FIND="${pkgs.findutils}/bin/find"
    SHUF="${pkgs.coreutils}/bin/shuf"
    MD5SUM="${pkgs.coreutils}/bin/md5sum"
    FLOCK="${pkgs.util-linux}/bin/flock"
    HEAD="${pkgs.coreutils}/bin/head"
    SED="${pkgs.gnused}/bin/sed"

    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    CACHE_BLUR_DIR="$HOME/.cache/niri-blur"
    OVERVIEW_WALL_TMP="$HOME/.cache/overview_wallpaper.jpg"
    PLAYLIST="$HOME/.cache/niri-wallpaper-playlist.txt"

    mkdir -p "$CACHE_BLUR_DIR"

    # --- LÓGICA DE BARAJA (SIN REPETICIONES) ---
    WALLPAPER=""

    # Bucle por si borraste una foto que estaba en la lista
    while true; do
        # Si la playlist no existe o está vacía, barajamos todo de nuevo
        if [ ! -s "$PLAYLIST" ]; then
            $FIND "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | $SHUF > "$PLAYLIST"
        fi

        # Leemos la primera línea
        WALLPAPER=$($HEAD -n 1 "$PLAYLIST")
        
        # Borramos esa primera línea para no repetirla
        $SED -i '1d' "$PLAYLIST"

        # Comprobamos que el archivo sigue existiendo en tu disco
        if [ -f "$WALLPAPER" ]; then
            break # Encontramos un fondo válido, salimos del bucle
        fi
    done
    # ---------------------------------------------

    if [ -z "$WALLPAPER" ]; then
        exit 1
    fi

    # Hash único y caché
    WALL_HASH=$(echo "$WALLPAPER" | $MD5SUM | cut -d' ' -f1)
    CACHED_PHOTO="$CACHE_BLUR_DIR/$WALL_HASH.jpg"

    if [ ! -f "$CACHED_PHOTO" ]; then
        if ! $MAGICK "$WALLPAPER" -filter Triangle -resize 140% -blur 0x6 "$CACHED_PHOTO"; then
            exit 1
        fi
    fi

    cp "$CACHED_PHOTO" "$OVERVIEW_WALL_TMP"

    # Esperar al daemon de awww (Max 5 segundos)
    MAX_INTENTOS=10
    INTENTO=0
    until $AWWW query >/dev/null 2>&1; do
        if [ $INTENTO -ge $MAX_INTENTOS ]; then
            exit 1
        fi
        sleep 0.5
        INTENTO=$((INTENTO+1))
    done

    # Aplicar fondos
    $AWWW img "$WALLPAPER" --transition-type fade

    pkill swaybg || true
    $SWAYBG -i "$OVERVIEW_WALL_TMP" -m fill &
  '';

  spotify-startup = pkgs.writeShellScriptBin "spotify-startup" ''
    #!/bin/sh
    if flatpak list | grep -qi spotify; then
      flatpak run com.spotify.Client
    else
       spotify
    fi
  '';
}
