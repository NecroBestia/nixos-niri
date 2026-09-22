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
# 2. noctalia-sync — LOS AJUSTES DE LA GUI VUELVEN AL FLAKE:
#    En Noctalia 5.x la GUI NO escribe config.toml: guarda lo que tocas en
#    ~/.local/state/noctalia/settings.toml, que es el overlay FINAL (gana
#    sobre config.toml). Por eso el punto 1 no alcanza para conservar los
#    ajustes: viven solo en el state dir y se pierden al limpiar la máquina
#    o al pasar a otro host.
#    `noctalia-sync` (config/noctalia/scripts/noctalia-sync) corre
#    `noctalia config export merged` (= config.toml ∪ settings.toml,
#    normalizado), descarta las tablas de ESTADO (wallpaper.last,
#    wallpaper.monitors) y fusiona el resto en el TOML del flake del host
#    con tomlkit: preserva comentarios y orden, y solo agrega/actualiza
#    claves (nunca borra). Se dispara de tres formas:
#      - noctalia-sync.path (systemd user): vigila settings.toml y corre el
#        sync en cada guardado de la GUI.
#      - activación de Home Manager: una pasada en cada `hm-switch`.
#      - a mano: `noctalia-sync --dry-run` para ver qué cambiaría.
#    OJO: mientras una clave siga en settings.toml, el overlay gana sobre el
#    flake. Si editás el flake a mano y querés que ese valor mande, sacá la
#    clave del overlay (o cambiala desde la GUI) y volvé a correr el sync.
#
# 3. templates/ y el stub de .cache quedan como estaban.
#===================================================================
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.noctalia;

  # config.programs.noctalia.settings apunta a la COPIA EN EL STORE del flake
  # (Nix copia el árbol —sucio incluido— a /nix/store/<hash>-source y evalúa
  # desde ahí), y el store es read-only: escribir el TOML del flake a través
  # de esa ruta es imposible. Se traduce de vuelta al repo real quitándole el
  # prefijo del source del flake y anteponiendo el directorio del repo.
  # Si algún día movés el repo, sobreescribí noctaliaSync.flakeConfig.
  flakeDir = "${config.home.homeDirectory}/nixFlake";
  storeRoot = toString inputs.self.outPath;
  settingsPath = toString config.programs.noctalia.settings;
  repoConfig =
    if lib.hasPrefix "${storeRoot}/" settingsPath then
      flakeDir + lib.removePrefix storeRoot settingsPath
    else
      settingsPath;

  # Wrapper: python3 + tomlkit para el script, y el CLI `noctalia` en PATH
  # (noctalia-sync usa `noctalia config export merged` y `config validate`).
  noctaliaSync = pkgs.writeShellApplication {
    name = "noctalia-sync";
    runtimeInputs = [
      (pkgs.python3.withPackages (ps: [ ps.tomlkit ]))
      cfg.package
    ];
    text = ''
      exec python3 ${../config/noctalia/scripts/noctalia-sync} \
        --flake-config ${toString config.noctaliaSync.flakeConfig} "$@"
    '';
  };
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  options.noctaliaSync.flakeConfig = lib.mkOption {
    type = lib.types.str;
    default = repoConfig;
    defaultText = lib.literalExpression ''
      "<home>/nixFlake" + (ruta de programs.noctalia.settings sin el prefijo del store)
    '';
    description = ''
      Ruta ABSOLUTA en el repo del TOML que noctalia-sync mantiene espejado.
      Se deriva de programs.noctalia.settings, así cada host espeja el suyo
      (config.toml en desktop, configNotebook.toml en notebook). Es un string
      a propósito: como path de Nix apuntaría a la copia read-only del store.
    '';
  };

  config = {
    programs.noctalia = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

      systemd.enable = true;

      settings = lib.mkDefault ../config/noctalia/config.toml;
    };

    home.packages = [ noctaliaSync ];

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

    # Pasada del sync en cada switch: los ajustes que la GUI guardó mientras
    # no había unidad corriendo (o antes del primer deploy) quedan en el flake.
    # El runtime ya los tenía vía settings.toml, así que no hay desfase: el
    # TOML del flake queda al día para la PRÓXIMA generación.
    home.activation.noctaliaSyncFlake =
      config.lib.dag.entryAfter [ "ensureWritableNoctaliaConfig" ] ''
        if ! ${noctaliaSync}/bin/noctalia-sync; then
          echo "noctalia-sync: no se pudo espejar la config en el TOML del flake" >&2
        fi
      '';

    systemd.user.services.noctalia-sync = {
      Unit = {
        Description = "Espeja los ajustes de la GUI de Noctalia en el TOML del flake";
        Documentation = [ "https://docs.noctalia.dev/noctalia/configuration/" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${noctaliaSync}/bin/noctalia-sync";
      };
    };

    # PathModified + PathChanged: Noctalia escribe settings.toml de forma
    # atómica (tmp + rename), así que hacen falta los dos eventos para no
    # perder ningún guardado.
    systemd.user.paths.noctalia-sync = {
      Unit.Description = "Vigila settings.toml de Noctalia y dispara noctalia-sync";
      Path = {
        PathChanged = "${config.xdg.stateHome}/noctalia/settings.toml";
        PathModified = "${config.xdg.stateHome}/noctalia/settings.toml";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
