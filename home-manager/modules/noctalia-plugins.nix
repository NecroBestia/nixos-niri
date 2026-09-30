#===================================================================
# NOCTALIA PLUGINS — plugins fijados por Nix (instalación declarativa)
#===================================================================
# QUÉ HACE
#   1. CÓDIGO: extrae cada plugin de su repo fuente con un sparse checkout
#      fijado por rev + hash, y enlaza el subdirectorio en:
#          ${XDG_DATA_HOME}/noctalia/plugins/<subdir>  →  /nix/store/…
#      Ese directorio es la fuente incorporada "local" de Noctalia, la de MAYOR
#      precedencia: gana sobre cualquier copia exportada de official/community.
#   2. DEPENDENCIAS: un plugin no es un ejecutable que se pueda envolver —
#      corre dentro de Noctalia (Luau) e invoca comandos externos que heredan
#      el PATH del proceso `noctalia`. Este módulo lee el `dependencies` de cada
#      manifiesto, lo mapea a paquetes de nixpkgs y publica esa lista en
#      `noctaliaPlugins.pathPackages`; modules/noctalia.nix envuelve el binario
#      `noctalia` con ese PATH (solo ese proceso, no el PATH global).
#
# QUÉ NO HACE
#   No decide qué plugins están ACTIVOS. Eso sigue en [plugins].enabled del
#   TOML del flake (config/noctalia/config.toml), que es la única fuente de
#   "activo". Este módulo solo despliega código, resuelve dependencias y avisa
#   si hay desajuste.
#
# OJO CON EL OVERLAY DE LA GUI
#   Noctalia aplica ~/.local/state/noctalia/settings.toml AL FINAL y deepMerge
#   reemplaza arrays completos: un [plugins] enabled en ese archivo ANULA la
#   lista del flake. Si la GUI vuelve a escribir esa clave, hay que borrarla
#   (ver spec.md del plan: ~/Projects/opencodePlans/noctalia-plugins-declarativos).
#
# AÑADIR O ACTUALIZAR UN PLUGIN
#   1. Su id en [plugins].enabled del TOML del flake.
#   2. Su pin acá (rev + hash). Procedimiento en el README del plan.
#   Si el plugin declara una dependencia sin mapeo, la evaluación falla con el
#   nombre exacto: se agrega el paquete en noctaliaPlugins.depPackageOverrides.
#===================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.noctaliaPlugins;

  # El subdirectorio en el repo es la parte del id tras la barra
  # (convención de los repos de plugins: "me/hello" vive en hello/).
  subdirOf =
    id: pin: if pin.subdir != null then pin.subdir else lib.last (lib.splitString "/" id);

  # Un fetch por plugin: sparse checkout del subdirectorio, fijado por rev+hash.
  # Un pin por plugin (y no uno por fuente con varios subdirs) para que añadir o
  # quitar un plugin no invalide el hash de los demás.
  fetched = lib.mapAttrs (
    id: pin:
    pkgs.fetchgit {
      inherit (pin) url rev hash;
      sparseCheckout = [ (subdirOf id pin) ];
    }
  ) cfg.pins;

  # Manifiestos leídos en evaluación: del `dependencies` declarado salen los
  # paquetes, y del `id` sale la verificación de la clave del pin. Es un
  # import-from-derivation sobre un fixed-output: se construye una vez (queda en
  # el store) y después la evaluación lo lee sin red.
  manifests = lib.mapAttrs (
    id: _: builtins.fromTOML (builtins.readFile "${fetched.${id}}/plugin.toml")
  ) cfg.pins;

  pinnedIds = builtins.attrNames cfg.pins;
  wrongId = lib.filter (id: (manifests.${id}.id or "") != id) pinnedIds;

  # Nombres de dependencia declarados por los plugins desplegados, sin repetir.
  depNames = lib.unique (lib.concatMap (m: m.dependencies or [ ]) (builtins.attrValues manifests));

  # Tabla nombre → paquete. `null` = lo provee el sistema (privilegiado o atado
  # al daemon en ejecución: envolverlo con otra copia lo rompería).
  table = curatedDepPackages // cfg.depPackageOverrides;
  unmapped = lib.filter (n: !(table ? ${n})) depNames;

  pathPackages =
    map (n: table.${n}) (lib.unique (lib.filter (n: table.${n} != null) depNames)) ++ cfg.extraPackages;

  # Directorio con un symlink por plugin.
  bundle = pkgs.runCommand "noctalia-plugins" { } (
    ''
      mkdir -p "$out"
    ''
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        id: pin:
        let
          sub = subdirOf id pin;
        in
        ''
          src="${fetched.${id}}/${sub}"
          if [ ! -f "$src/plugin.toml" ]; then
            echo "noctalia-plugins: '${id}': no existe ${sub}/plugin.toml en ${pin.url} (rev ${pin.rev}). Revisa subdir, rev o hash." >&2
            exit 1
          fi
          ln -s "$src" "$out/${sub}"
        ''
      ) cfg.pins
    )
  );

  pluginFiles = lib.listToAttrs (
    lib.mapAttrsToList (id: pin: {
      name = "${config.xdg.dataHome}/noctalia/plugins/${subdirOf id pin}";
      value.source = "${bundle}/${subdirOf id pin}";
    }) cfg.pins
  );

  # Lista de activos, leída del TOML del flake en eval (path del árbol del flake:
  # puro, sin IFD). Solo para avisar de desajustes pin ↔ enabled.
  declared = builtins.fromTOML (builtins.readFile cfg.configFile);
  enabledIds = (declared.plugins or { }).enabled or [ ];
  sinPin = lib.subtractLists pinnedIds enabledIds;
  sinHabilitar = lib.subtractLists enabledIds pinnedIds;

  # ── Tabla de dependencias (nombre declarado → paquete) ───────────────────
  # Cobertura medida sobre community-plugins rev a4645e8: 627 usos, 271 nombres
  # distintos. Están los comandos con >=2 apariciones y los habituales del
  # ecosistema; lo que falte se agrega en depPackageOverrides.
  curatedSpec = [
    {
      pkg = pkgs.coreutils;
      names = [
        "basename"
        "cat"
        "chgrp"
        "chmod"
        "cp"
        "cut"
        "date"
        "dd"
        "df"
        "dirname"
        "du"
        "env"
        "head"
        "id"
        "install"
        "ln"
        "ls"
        "mkdir"
        "mktemp"
        "mv"
        "nohup"
        "printf"
        "readlink"
        "realpath"
        "rm"
        "seq"
        "sha256sum"
        "sleep"
        "sort"
        "stat"
        "stdbuf"
        "tail"
        "tee"
        "test"
        "timeout"
        "tr"
        "uniq"
        "wc"
        "whoami"
      ];
    }
    {
      pkg = pkgs.procps;
      names = [
        "free"
        "kill"
        "pgrep"
        "pidof"
        "pkill"
        "ps"
        "top"
        "uptime"
        "watch"
      ];
    }
    {
      pkg = pkgs.util-linux;
      names = [
        "blkid"
        "dmesg"
        "findmnt"
        "flock"
        "hexdump"
        "logger"
        "lscpu"
        "lsblk"
        "mount"
        "nsenter"
        "rfkill"
        "setsid"
        "umount"
        "unshare"
      ];
    }
    {
      pkg = pkgs.findutils;
      names = [
        "find"
        "xargs"
      ];
    }
    {
      pkg = pkgs.gnugrep;
      names = [
        "egrep"
        "fgrep"
        "grep"
        "rgrep"
      ];
    }
    {
      pkg = pkgs.gnused;
      names = [ "sed" ];
    }
    {
      pkg = pkgs.gawk;
      names = [
        "awk"
        "gawk"
      ];
    }
    {
      pkg = pkgs.bash;
      names = [
        "bash"
        "sh"
      ];
    }
    {
      pkg = pkgs.python3;
      names = [
        "python"
        "python3"
      ];
    }
    {
      pkg = pkgs.iproute2;
      names = [
        "ip"
        "ss"
      ];
    }
    {
      pkg = pkgs.iputils;
      names = [
        "ping"
        "ping6"
      ];
    }
    {
      pkg = pkgs.glib;
      names = [
        "gapplication"
        "gdbus"
        "gio"
        "gsettings"
      ];
    }
    {
      pkg = pkgs.xdg-utils;
      names = [
        "xdg-mime"
        "xdg-open"
        "xdg-settings"
        "xdg-utils"
      ];
    }
    {
      pkg = pkgs.openssh;
      names = [
        "scp"
        "sftp"
        "ssh"
        "ssh-add"
        "ssh-keygen"
      ];
    }
    {
      pkg = pkgs.pulseaudio;
      names = [
        "pacmd"
        "pactl"
        "paplay"
        "parec"
        "parecord"
      ];
    }
    {
      pkg = pkgs.pipewire;
      names = [
        "pw-cli"
        "pw-dump"
        "pw-link"
        "pw-play"
        "pw-record"
      ];
    }
    {
      pkg = pkgs.wireplumber;
      names = [ "wpctl" ];
    }
    {
      pkg = pkgs.bluez;
      names = [ "bluetoothctl" ];
    }
    {
      pkg = pkgs.networkmanager;
      names = [
        "nmcli"
        "nmtui"
      ];
    }
    {
      pkg = pkgs.alsa-utils;
      names = [
        "alsamixer"
        "amixer"
        "aplay"
        "arecord"
      ];
    }
    {
      pkg = pkgs.wl-clipboard;
      names = [
        "wl-copy"
        "wl-paste"
      ];
    }
    {
      pkg = pkgs.libnotify;
      names = [
        "notify-send"
        "notify-send.py"
      ];
    }
    {
      pkg = pkgs.libsecret;
      names = [ "secret-tool" ];
    }
    {
      pkg = pkgs.imagemagick;
      names = [
        "convert"
        "identify"
        "magick"
      ];
    }
    {
      pkg = pkgs.python3Packages.pygobject3;
      names = [ "python-gobject" ];
    }
    {
      pkg = pkgs.gtk3;
      names = [
        "gtk-launch"
        "gtk3"
      ];
    }
    {
      pkg = pkgs.gtk-layer-shell;
      names = [ "gtk-layer-shell" ];
    }
    {
      pkg = pkgs.jq;
      names = [ "jq" ];
    }
    {
      pkg = pkgs.curl;
      names = [ "curl" ];
    }
    {
      pkg = pkgs.wget;
      names = [ "wget" ];
    }
    {
      pkg = pkgs.git;
      names = [ "git" ];
    }
    {
      pkg = pkgs.socat;
      names = [ "socat" ];
    }
    {
      pkg = pkgs.netcat;
      names = [
        "nc"
        "netcat"
      ];
    }
    {
      pkg = pkgs.openssl;
      names = [ "openssl" ];
    }
    {
      pkg = pkgs.gnupg;
      names = [ "gpg" ];
    }
    {
      pkg = pkgs.pass;
      names = [ "pass" ];
    }
    {
      pkg = pkgs.passExtensions.pass-otp;
      names = [ "pass-otp" ];
    }
    {
      pkg = pkgs.fzf;
      names = [ "fzf" ];
    }
    {
      pkg = pkgs.ripgrep;
      names = [ "rg" ];
    }
    {
      pkg = pkgs.fd;
      names = [ "fd" ];
    }
    {
      pkg = pkgs.bat;
      names = [ "bat" ];
    }
    {
      pkg = pkgs.less;
      names = [ "less" ];
    }
    {
      pkg = pkgs.file;
      names = [ "file" ];
    }
    {
      pkg = pkgs.tree;
      names = [ "tree" ];
    }
    {
      pkg = pkgs.bc;
      names = [ "bc" ];
    }
    {
      pkg = pkgs.unzip;
      names = [ "unzip" ];
    }
    {
      pkg = pkgs.zip;
      names = [ "zip" ];
    }
    {
      pkg = pkgs.gnutar;
      names = [ "tar" ];
    }
    {
      pkg = pkgs.gzip;
      names = [
        "gunzip"
        "gzip"
      ];
    }
    {
      pkg = pkgs.rsync;
      names = [ "rsync" ];
    }
    {
      pkg = pkgs.sshfs;
      names = [ "sshfs" ];
    }
    {
      pkg = pkgs.sqlite;
      names = [ "sqlite3" ];
    }
    {
      pkg = pkgs.tailscale;
      names = [ "tailscale" ];
    }
    {
      pkg = pkgs.upower;
      names = [ "upower" ];
    }
    {
      pkg = pkgs.power-profiles-daemon;
      names = [ "powerprofilesctl" ];
    }
    {
      pkg = pkgs.playerctl;
      names = [ "playerctl" ];
    }
    {
      pkg = pkgs.pamixer;
      names = [ "pamixer" ];
    }
    {
      pkg = pkgs.brightnessctl;
      names = [ "brightnessctl" ];
    }
    {
      pkg = pkgs.gh;
      names = [ "gh" ];
    }
    {
      pkg = pkgs.zenity;
      names = [ "zenity" ];
    }
    {
      pkg = pkgs.qrencode;
      names = [ "qrencode" ];
    }
    {
      pkg = pkgs.yt-dlp;
      names = [ "yt-dlp" ];
    }
    {
      pkg = pkgs.ffmpeg;
      names = [
        "ffmpeg"
        "ffprobe"
      ];
    }
    {
      pkg = pkgs.grim;
      names = [ "grim" ];
    }
    {
      pkg = pkgs.slurp;
      names = [ "slurp" ];
    }
    {
      pkg = pkgs.wl-mirror;
      names = [ "wl-mirror" ];
    }
    {
      pkg = pkgs.mpv;
      names = [ "mpv" ];
    }
    {
      pkg = pkgs.wtype;
      names = [ "wtype" ];
    }
    {
      pkg = pkgs.ydotool;
      names = [ "ydotool" ];
    }
    {
      pkg = pkgs.entr;
      names = [ "entr" ];
    }
    {
      pkg = pkgs.inotify-tools;
      names = [ "inotifywait" ];
    }
    # Del sistema: privilegiado, atado al daemon en ejecución, del compositor o
    # del propio host. Envolverlos con otra copia del store los rompería.
    {
      pkg = null;
      names = [
        "busctl"
        "coredumpctl"
        "getent"
        "groupadd"
        "hostnamectl"
        "hyprctl"
        "hyprland"
        "journalctl"
        "labwc"
        "localectl"
        "loginctl"
        "mango"
        "mmsg"
        "networkctl"
        "niri"
        "nix"
        "omp"
        "opencode"
        "pacman"
        "pkexec"
        "resolvectl"
        "sudo"
        "swaymsg"
        "systemctl"
        "systemd-cat"
        "systemd-inhibit"
        "systemd-run"
        "timedatectl"
        "udevadm"
        "umbriel"
        "usermod"
      ];
    }
  ];

  curatedDepPackages = lib.listToAttrs (
    lib.concatMap (entry: map (name: lib.nameValuePair name entry.pkg) entry.names) curatedSpec
  );
in
{
  options.noctaliaPlugins = {
    enable = lib.mkEnableOption "plugins de Noctalia fijados por Nix";

    configFile = lib.mkOption {
      type = lib.types.path;
      default = ../config/noctalia/config.toml;
      description = ''
        TOML del flake que manda sobre los plugins: su `[plugins].enabled` es la
        lista de plugins activos. Se lee en tiempo de evaluación solo para avisar
        cuando esa lista y los pins no coinciden.
      '';
    };

    depPackageOverrides = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.package);
      default = { };
      example = lib.literalExpression ''
        {
          "wl-copy" = pkgs.wl-clipboard;
          "sensors" = pkgs.lm_sensors;
          "nvidia-smi" = null; # lo provee el sistema
        }
      '';
      description = ''
        Ajustes sobre la tabla de dependencias incluida en el módulo
        (`nombre declarado en dependencies` → paquete que provee el comando).
        Un valor `null` marca la dependencia como provista por el sistema: no se
        agrega nada al PATH del shell y la verificación la da por cubierta.
        Sirve tanto para agregar nombres que falten como para corregir un mapeo.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "with pkgs; [ lm_sensors ]";
      description = ''
        Paquetes que se agregan al PATH del shell de Noctalia además de los
        resueltos desde `dependencies`. Para dependencias que no se declaran en el
        manifiesto, o que no son comandos (librerías vía GI_TYPELIB_PATH, etc.:
        para eso último ver `extraWrapperArgs`).
      '';
    };

    extraWrapperArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''
        [ "--prefix" "GI_TYPELIB_PATH" ":" "${pkgs.lib.makeTypelibPath [ pkgs.gtk3 ]}" ]
      '';
      description = ''
        Argumentos extra para el `wrapProgram` del binario `noctalia` (ver
        modules/noctalia.nix). Para dependencias que no se resuelven por PATH.
      '';
    };

    pathPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      readOnly = true;
      internal = true;
      default = [ ];
      description = ''
        Paquetes que proveen las dependencias de los plugins desplegados, más
        `extraPackages`. Lo consume modules/noctalia.nix para envolver el binario.
      '';
    };

    pins = lib.mkOption {
      default = { };
      description = ''
        Plugins fijados por Nix, indexados por su id canónico (`"author/plugin"`,
        tal como aparece en `id` del `plugin.toml`). Cada uno se extrae con sparse
        checkout de su repo fuente y se despliega como fuente "local" de Noctalia,
        la de mayor precedencia.
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
            subdir = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Subdirectorio del plugin dentro del repo; por defecto, la parte del id tras la barra.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    noctaliaPlugins.pathPackages = pathPackages;

    assertions = [
      {
        assertion = wrongId == [ ];
        message = "noctaliaPlugins: la clave del pin no coincide con el `id` del plugin.toml: ${lib.concatStringsSep ", " wrongId}";
      }
      {
        assertion = unmapped == [ ];
        message = "noctaliaPlugins: dependencias sin mapeo: ${lib.concatStringsSep ", " unmapped}. Agregalas a noctaliaPlugins.depPackageOverrides con el paquete que provee el comando, o con null si lo provee el sistema.";
      }
    ];

    warnings =
      lib.optional (sinPin != [ ])
        "noctaliaPlugins: habilitados en ${toString cfg.configFile} sin pin en Nix (usan la copia de la fuente git, no reproducible): ${lib.concatStringsSep ", " sinPin}"
      ++ lib.optional (sinHabilitar != [ ])
        "noctaliaPlugins: fijados en Nix pero ausentes de [plugins].enabled en ${toString cfg.configFile} (código desplegado, inactivo): ${lib.concatStringsSep ", " sinHabilitar}";

    home.file = pluginFiles;
  };
}
