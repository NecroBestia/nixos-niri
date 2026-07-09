#===================================================================
# HIDDEN DOTFILES — Gestion de Dotfiles con .hidden/
#===================================================================
# Módulo que implementa la migración de dotfiles sueltos en $HOME
# a $HOME/.hidden/ con symlinks de vuelta. Incluye:
#
# 1. Activation hook: Mueve dotfiles existentes a .hidden/ en cada
#    home-manager switch (despues de writeBoundary).
# 2. Systemd watcher: Vigila $HOME con inotify para capturar nuevos
#    dotfiles creados por apps.
#
# ESTRATEGIA:
#   - Exclusiones (no se tocan): .hidden, .cache, .config, .local,
#     .nix-profile, .nix-defexpr, .dataSync, .Trash-1000,
#     .steampath, .steampid
#   - Symlinks HM (/nix/store): se saltan automaticamente
#   - Symlinks a .hidden/: se saltan (ya migrados)
#   - El resto: mv a .hidden/ + symlink
#===================================================================
{ config, pkgs, lib, ... }:

let
  scripts = import ./scripts.nix { inherit pkgs; };
  excludePattern = ".hidden|.cache|.config|.local|.nix-profile|.nix-defexpr|.dataSync|.Trash-1000|.steampath|.steampid";
in {
  #-----------------------------------------------------------------
  # ACTIVATION HOOK — Migracion en cada home-manager switch
  #-----------------------------------------------------------------
  # Corre despues de writeBoundary para que HM ya haya creado sus
  # propios symlinks. Asi podemos detectarlos y saltarlos.
  home.activation.moveHiddenFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    EXCLUDE="${excludePattern}"

    for item in "$HOME"/.[!.]*; do
      [ -e "$item" ] || continue
      name=$(basename "$item")

      echo "$name" | grep -qE "^($EXCLUDE)$" && continue

      if [ -L "$item" ] && [ "$(readlink "$item")" = "$HOME/.hidden/$name" ]; then
        continue
      fi

      if [ -L "$item" ]; then
        continue
      fi

      mkdir -p "$HOME/.hidden"

      if [ -e "$HOME/.hidden/$name" ]; then
        rm -rf "$item"
      else
        mv "$item" "$HOME/.hidden/$name"
      fi
      ln -sf "$HOME/.hidden/$name" "$item"
    done
  '';

  #-----------------------------------------------------------------
  # SYSTEMD WATCHER — Vigilancia en Tiempo Real
  #-----------------------------------------------------------------
  # Ejecuta watch-hidden-files como servicio persistente.
  # Se reinicia automaticamente si falla.
  systemd.user.services.hidden-dotfiles-watcher = {
    Unit = {
      Description = "Watch for new hidden files in $HOME and move to .hidden/";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${scripts.watch-hidden-files}/bin/watch-hidden-files";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  #-----------------------------------------------------------------
  # PAQUETES
  #-----------------------------------------------------------------
  home.packages = [ pkgs.inotify-tools ];
}
