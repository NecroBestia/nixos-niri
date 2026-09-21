#===================================================================
# NOCTALIA — Shell Wayland (bar, launcher, notifs, wallpaper, temas)
#===================================================================
# Además del módulo upstream (inputs.noctalia.homeModules.default):
#
# 1. config.toml ESCRIBIBLE:
#    El módulo despliega ~/.config/noctalia/config.toml como symlink
#    read-only al store (xdg.configFile). Noctalia lo reescribe en
#    caliente desde su GUI de ajustes (y desde los toggles del panel),
#    así que sobre un symlink al store el guardado falla o reemplaza
#    el symlink (perdiendo el archivo declarativo).
#
#    Solución (misma que los .kdl de niri, ver modules/niri.nix):
#      - force = true  → el próximo switch vuelve a imponer el TOML
#        declarativo aunque en disco haya un archivo regular.
#      - activación post-linkGeneration → convierte el symlink en copia
#        escribible, para que la GUI pueda guardar durante la sesión.
#    Trade-off conocido: cada `hm-switch` re-impone el TOML del flake y
#    descarta lo que hayas cambiado desde la GUI en esa sesión. Si un
#    ajuste te gusta, pasalo al config.toml del repo.
#
# 2. templates/ y el stub de .cache quedan como estaban.
#===================================================================
{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    systemd.enable = true;

    settings = lib.mkDefault ../config/noctalia/config.toml;
  };

  home.file.".cache/noctalia-symlink-stub".text = ''
    # Stub — deleted after first wallpaper change creates the actual symlink
  '';

  home.file.".config/noctalia/templates/".source = ../config/noctalia/templates;

  # Necesario para que linkGeneration pueda reemplazar la copia escribible
  # que deja la activación de abajo (si no, HM aborta con "Existing file
  # would be clobbered" al encontrar un archivo regular en esa ruta).
  # mkForce porque modules/misc/xdg.nix fija force = false explícitamente.
  home.file."${config.xdg.configHome}/noctalia/config.toml".force = lib.mkForce true;

  home.activation.ensureWritableNoctaliaConfig =
    config.lib.dag.entryAfter [ "linkGeneration" ] ''
      noctalia_cfg="${config.xdg.configHome}/noctalia/config.toml"
      if [ -L "$noctalia_cfg" ]; then
        target=$(readlink -f "$noctalia_cfg" 2>/dev/null || true)
        if [ -n "$target" ] && [ -f "$target" ]; then
          rm -f "$noctalia_cfg" && cp "$target" "$noctalia_cfg" && chmod u+w "$noctalia_cfg"
        fi
      fi
    '';
}
