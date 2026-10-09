#===================================================================
# NOCTALIA PLUGINS — plugins fijados por Nix
#===================================================================
# CÓDIGO
#   Extrae cada plugin con sparse checkout fijado por rev + hash y lo enlaza en
#   ${XDG_DATA_HOME}/noctalia/plugins/<subdir>, que Noctalia escanea como fuente
#   "local": la de MAYOR precedencia, gana sobre las copias de official/community.
#
# DEPENDENCIAS
#   Un plugin no es un ejecutable: corre dentro de Noctalia (Luau) e invoca
#   comandos externos que resuelven por el PATH del proceso `noctalia`
#   (::execvp, src/core/process/process.cpp). Los paquetes se declaran en
#   `packages` y modules/noctalia.nix envuelve el binario con ese PATH; el PATH
#   global de la sesión no se toca. No hay tabla nombre→paquete que mantener: el
#   build verifica que cada `dependencies` de los manifiestos desplegados
#   resuelva en ese PATH y falla nombrando lo que falta (mapa de nombres
#   frecuentes: README del plan).
#
# ACTIVOS
#   La lista de plugins activos vive en [plugins].enabled del TOML del flake.
#   OJO: el overlay de la GUI (~/.local/state/noctalia/settings.toml) la ANULA
#   si tiene [plugins], porque deepMerge reemplaza arrays completos.
#===================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.noctaliaPlugins;

  # "author/plugin" → plugin (convención de los repos de plugins).
  subdirOf = id: lib.last (lib.splitString "/" id);

  fetched = lib.mapAttrs (
    id: pin:
    pkgs.fetchgit {
      inherit (pin) url rev hash;
      sparseCheckout = [ (subdirOf id) ];
    }
  ) cfg.pins;

  # Una sola derivación: enlaza los plugins y verifica manifiestos y
  # dependencias. Si algo no cuadra, el switch falla con el detalle, en vez de
  # dejar un symlink colgando (que Noctalia ignora en silencio) o un plugin
  # desplegado que invoca comandos inexistentes.
  bundle = pkgs.runCommand "noctalia-plugins" {
    binPath = lib.makeBinPath cfg.packages;
    ignored = lib.concatStringsSep " " cfg.ignoredDependencies;
  } ''
    mkdir -p "$out"
    missing=""

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        id: _:
        let
          sub = subdirOf id;
        in
        ''
          src="${fetched.${id}}/${sub}"
          manifest="$src/plugin.toml"
          if [ ! -f "$manifest" ]; then
            echo "noctalia-plugins: '${id}': no hay ${sub}/plugin.toml en el rev fijado (revisa rev o hash)" >&2
            exit 1
          fi
          declared=$(sed -n 's/^id *= *"\(.*\)"/\1/p' "$manifest" | head -n1)
          if [ "$declared" != "${id}" ]; then
            echo "noctalia-plugins: '${id}': el manifiesto declara id = \"$declared\"; la clave del pin debe ser ese id" >&2
            exit 1
          fi
          ln -s "$src" "$out/${sub}"

          for dep in $(sed -n 's/^dependencies *= *\[\(.*\)\]/\1/p' "$manifest" | tr ',' ' ' | tr -d '"'); do
            case " $ignored " in *" $dep "*) continue ;; esac
            ok=""
            for dir in $(echo "$binPath" | tr ':' ' '); do
              if [ -x "$dir/$dep" ]; then ok=1; break; fi
            done
            [ -n "$ok" ] || missing="$missing $dep"
          done
        ''
      ) cfg.pins
    )}

    if [ -n "$missing" ]; then
      echo "noctalia-plugins: dependencias que no resuelven en el PATH del wrapper:$missing" >&2
      echo "  Agrégalas a noctaliaPlugins.packages, o a ignoredDependencies si las" >&2
      echo "  provee el sistema o no son comandos (mapa de nombres: README del plan)." >&2
      exit 1
    fi
  '';

  pluginFiles = lib.listToAttrs (
    lib.mapAttrsToList (id: _: {
      name = "${config.xdg.dataHome}/noctalia/plugins/${subdirOf id}";
      value.source = "${bundle}/${subdirOf id}";
    }) cfg.pins
  );

  # Lista de activos, leída del TOML del flake (archivo del árbol: lectura pura,
  # sin red ni derivaciones). Solo para avisar de desajustes pin ↔ enabled.
  declared = builtins.fromTOML (builtins.readFile cfg.configFile);
  enabledIds = (declared.plugins or { }).enabled or [ ];
  pinnedIds = builtins.attrNames cfg.pins;
  sinPin = lib.subtractLists pinnedIds enabledIds;
  sinHabilitar = lib.subtractLists enabledIds pinnedIds;
in
{
  options.noctaliaPlugins = {
    enable = lib.mkEnableOption "plugins de Noctalia fijados por Nix";

    configFile = lib.mkOption {
      type = lib.types.path;
      default = ../config/noctalia/config.toml;
      description = ''
        TOML del flake que manda sobre los plugins: su `[plugins].enabled` es la
        lista de plugins activos. Se lee en evaluación solo para avisar cuando esa
        lista y los pins no coinciden.
      '';
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression ''
        with pkgs; [ fzf findutils util-linux glib xdg-utils coreutils pulseaudio bluez ]
      '';
      description = ''
        Paquetes que proveen los comandos que invocan los plugins. Se anteponen al
        PATH del binario `noctalia` (modules/noctalia.nix), no al de la sesión. El
        build verifica que cubran todos los `dependencies` de los manifiestos
        desplegados.
      '';
    };

    ignoredDependencies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "sudo"
        "systemctl"
        "niri"
      ];
      description = ''
        Nombres de `dependencies` que el wrapper no tiene que resolver por PATH:
        los provee el sistema (privilegiado o atado al daemon en ejecución) o no
        son comandos (librerías). La verificación los da por cubiertos.
      '';
    };

    extraWrapperArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''
        [ "--prefix" "GI_TYPELIB_PATH" ":" (pkgs.lib.makeTypelibPath [ pkgs.gtk3 ]) ]
      '';
      description = ''
        Argumentos extra para el `wrapProgram` del binario `noctalia`. Para
        dependencias que no se resuelven por PATH.
      '';
    };

    pins = lib.mkOption {
      default = { };
      description = ''
        Plugins fijados por Nix, indexados por su id canónico (`"author/plugin"`,
        el `id` del `plugin.toml`). El subdirectorio en el repo es la parte del id
        tras la barra.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            url = lib.mkOption {
              type = lib.types.str;
              description = "URL del repo de plugins (la misma que usa la fuente git de Noctalia).";
            };
            rev = lib.mkOption {
              type = lib.types.str;
              description = "Commit completo del repo del que se extrae el plugin.";
            };
            hash = lib.mkOption {
              type = lib.types.str;
              description = "Hash SRI del sparse checkout de ese subdirectorio (ver README del plan para calcularlo).";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      lib.optional (sinPin != [ ])
        "noctaliaPlugins: habilitados en ${toString cfg.configFile} sin pin en Nix (usan la copia de la fuente git, no reproducible): ${lib.concatStringsSep ", " sinPin}"
      ++ lib.optional (sinHabilitar != [ ])
        "noctaliaPlugins: fijados en Nix pero ausentes de [plugins].enabled en ${toString cfg.configFile} (código desplegado, inactivo): ${lib.concatStringsSep ", " sinHabilitar}";

    home.file = pluginFiles;
  };
}
