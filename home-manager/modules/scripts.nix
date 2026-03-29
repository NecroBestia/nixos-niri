{pkgs, ...}: 
{
  clipboard = pkgs.writeShellScriptBin "niri-clipboard" 
  '' 
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
    SWWW="${pkgs.swww}/bin/swww"
    MAGICK="${pkgs.imagemagick}/bin/magick"
    SWAYBG="${pkgs.swaybg}/bin/swaybg"
    FIND="${pkgs.findutils}/bin/find"
    SHUF="${pkgs.coreutils}/bin/shuf"
    MD5SUM="${pkgs.coreutils}/bin/md5sum"

    WALLPAPER_DIR="$HOME/Wallpapers"
    # Carpeta específica para los fondos con blur
    CACHE_BLUR_DIR="$HOME/.cache/niri-blur"
    OVERVIEW_WALL_TMP="$HOME/.cache/overview_wallpaper.jpg"

    # Crear carpetas si no existen
    mkdir -p "$CACHE_BLUR_DIR"

    # 1. Elegir un wallpaper aleatorio
    WALLPAPER=$($FIND "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | $SHUF -n 1)

    if [ -z "$WALLPAPER" ]; then
        exit 1
    fi

    # 2. Generar un nombre único basado en la ruta del archivo (usando md5)
    # Esto evita conflictos si dos fotos se llaman igual pero están en carpetas distintas
    WALL_HASH=$(echo "$WALLPAPER" | $MD5SUM | cut -d' ' -f1)
    CACHED_PHOTO="$CACHE_BLUR_DIR/$WALL_HASH.jpg"

    # 3. Lógica de Caché: ¿Ya existe la versión con blur?
    if [ ! -f "$CACHED_PHOTO" ]; then
        # No existe, la creamos
        $MAGICK "$WALLPAPER" -filter Triangle -resize 140% -blur 0x6 "$CACHED_PHOTO"
    fi

    # 4. Copiar de la caché al archivo que usa swaybg (para mantener consistencia)
    cp "$CACHED_PHOTO" "$OVERVIEW_WALL_TMP"

    until $SWWW query >/dev/null 2>&1; do
        sleep 0.5
    done
    # 5. Aplicar fondos
    $SWWW img "$WALLPAPER" --transition-type fade
    
    pkill swaybg || true
    $SWAYBG -i "$OVERVIEW_WALL_TMP" -m fill &
  '';
}
