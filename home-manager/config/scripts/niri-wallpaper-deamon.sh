#!/usr/bin/env bash

# Carpeta de wallpapers
WALLPAPER_DIR="$HOME/Wallpapers"
CACHE_DIR="$HOME/.cache"
OVERVIEW_WALL="$CACHE_DIR/overview_wallpaper.jpg"

# Crear carpeta de cache si no existe
mkdir -p "$CACHE_DIR"

# Elegir un wallpaper aleatorio
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)

# -------------------------
# Procesar imagen con magick para overview (blur + zoom)
# -------------------------
BLUR=6
ZOOM=140
FILTER=Triangle

magick "$WALLPAPER" -filter $FILTER -resize ${ZOOM}% -blur 0x$BLUR "$OVERVIEW_WALL"

# -------------------------
# Fondo normal con swww (sin efectos)
# -------------------------
swww img "$WALLPAPER" --transition-type fade --transition-duration 1.0

# -------------------------
# Fondo de overview con swaybg
# -------------------------
swaybg -i "$OVERVIEW_WALL" -m fill &

