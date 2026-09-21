#===================================================================
# DEEPSEEK HARNESS (dsh) — Wrapper sin node global
#===================================================================
# Wrapper proxy para DeepSeek Harness (@deepseek-ai/dsh).
#
# Node.js NO se instala globalmente: el wrapper referencia el node
# desde el closure (ruta del nix store) y solo lo expone al comando
# `dsh`. El resto del sistema no ve node en el PATH.
#
# NOTA (--expose-internals): dsh arranca un servicio HMR vía
# cordis-plugin-hmr que requiere ese flag en el proceso node.
# node no lo permite vía NODE_OPTIONS, así que el wrapper resuelve el
# binario real de dsh y lo ejecuta directamente con el flag.
#
# RESOLUCIÓN (2026-09-10): el wrapper ya no llama a npx en cada
# arranque. Resuelve la instalación leyendo el disco — el enlace del
# perfil (~/.dsh/profiles/node_modules/@deepseek-ai/dsh) y las cachés
# de npx (~/.npm/_npx/*) — y ejecuta la versión más alta que
# encuentre: arranca sin red, sin escribir en ~/.npm y funciona
# incluso dentro de sandboxes que solo dejan escribir en el workspace.
# Si no encuentra nada, falla con mensaje y exit 127 (antes se quedaba
# callado) y solo entonces cae a npx, que sí necesita red. Para
# actualizar el paquete: `dsh-update`.
#
# PANEL DE APROBACIÓN (2026-09-10): `dsh-patch-approval` añade la
# opción "Always allow" al panel de aprobación del cliente: el permiso
# dura la sesión, por herramienta, y se implementa entero en el cliente
# (el host solo conoce 'allowed-once', así que el plugin recuerda el
# toolName en sessionStorage y responde solo). Es un parche del bundle
# ya compilado, idempotente y con anclajes que fallan en voz alta; se
# re-aplica en cada `hm-switch` y después de cada `dsh-update`.
#===================================================================
{ pkgs, lib, ... }:
let
  nodejs = pkgs.nodejs_24;

  # Parche del panel de aprobación ("Always allow" por tool y sesión).
  approvalPatch = pkgs.writeShellScriptBin "dsh-patch-approval" ''
    export DSH_APPROVAL_TEST="${./../config/dsh/test-approval.mjs}"
    exec "${nodejs}/bin/node" "${./../config/dsh/approval-always.mjs}" "$@"
  '';
in {
  home.packages = [
    (pkgs.writeShellScriptBin "dsh" ''
      set -uo pipefail

      export PATH="${nodejs}/bin:$PATH"
      NODE_BIN="${nodejs}/bin/node"

      die() {
        printf 'dsh: %s\n' "$1" >&2
        shift
        for line in "$@"; do printf '     %s\n' "$line" >&2; done
        exit 127
      }

      # Rutas candidatas a contener @deepseek-ai/dsh (todas de solo lectura).
      candidates() {
        [ -n "''${DSH_INSTALL:-}" ] && printf '%s\n' "''${DSH_INSTALL%/}/lib/bin.js"
        printf '%s\n' "$HOME/.dsh/profiles/node_modules/@deepseek-ai/dsh/lib/bin.js"
        local dir
        for dir in "$HOME"/.npm/_npx/*/node_modules/@deepseek-ai/dsh; do
          [ -f "$dir/lib/bin.js" ] && printf '%s\n' "$dir/lib/bin.js"
        done
      }

      pkg_version() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n 1; }

      # is_newer CANDIDATA ACTUAL — ¿CANDIDATA es más nueva? La base numérica
      # manda y una release gana a su propio pre-release (0.1.5 > 0.1.5-rc.1).
      is_newer() {
        local cand=$1 cur=$2 cbase=''${1%%-*} ubase=''${2%%-*}
        if [ "$cand" = "$cur" ]; then return 1; fi
        if [ "$cbase" != "$ubase" ]; then
          [ "$(printf '%s\n%s\n' "$ubase" "$cbase" | sort -V | tail -n 1)" = "$cbase" ]
          return
        fi
        if [ "$cand" = "$cbase" ]; then return 0; fi
        if [ "$cur" = "$ubase" ]; then return 1; fi
        [ "$(printf '%s\n%s\n' "$cur" "$cand" | sort -V | tail -n 1)" = "$cand" ]
      }

      best=""
      best_ver=""
      while IFS= read -r cand; do
        [ -n "$cand" ] && [ -f "$cand" ] || continue
        ver=$(pkg_version "$(dirname "$(dirname "$cand")")/package.json")
        [ -n "$ver" ] || continue
        if [ -z "$best_ver" ] || is_newer "$ver" "$best_ver"; then
          best=$cand
          best_ver=$ver
        fi
      done < <(candidates)

      if [ -z "$best" ]; then
        printf 'dsh: no encuentro @deepseek-ai/dsh instalado; resolviendo con npx (necesita red)...\n' >&2
        resolved=$(npx --yes --fetch-retries=1 --fetch-timeout=30000 -p @deepseek-ai/dsh -c 'command -v dsh') || die \
          'npx no pudo resolver el paquete.' \
          "Instálalo a mano: npx --yes -p @deepseek-ai/dsh -c 'dsh -V'" \
          'O apunta a una copia existente con DSH_INSTALL=/ruta/a/node_modules/@deepseek-ai/dsh'
        best=$(readlink -f "$resolved")
        [ -f "$best" ] || die "npx devolvió una ruta inválida: $resolved"
        best_ver=$(pkg_version "$(dirname "$(dirname "$best")")/package.json")
      fi

      real=$(readlink -f "$best")
      [ -n "$best_ver" ] || best_ver='?'
      if [ -n "''${DSH_DEBUG:-}" ]; then printf 'dsh: %s (%s)\n' "$real" "$best_ver" >&2; fi

      # Aviso discreto (solo TTY) si la copia resuelta lleva mucho sin actualizarse.
      if [ -t 2 ]; then
        install_dir=$(dirname "$(dirname "$real")")
        if [ -n "$(find "$install_dir" -maxdepth 0 -mtime +45 2>/dev/null)" ]; then
          printf 'dsh: esta copia de @deepseek-ai/dsh tiene más de 45 días; ejecuta dsh-update.\n' >&2
        fi
      fi

      exec "$NODE_BIN" --expose-internals "$real" "$@"
    '')
    (pkgs.writeShellScriptBin "dsh-update" ''
      set -uo pipefail

      export PATH="${nodejs}/bin:$PATH"
      NODE_BIN="${nodejs}/bin/node"

      printf 'dsh-update: resolviendo @deepseek-ai/dsh@latest con npx...\n'
      if ! resolved=$(npx --yes -p @deepseek-ai/dsh@latest -c 'command -v dsh'); then
        printf 'dsh-update: npx falló; la instalación existente no se tocó.\n' >&2
        exit 1
      fi
      real=$(readlink -f "$resolved")
      printf 'dsh-update: instalado en %s\n' "$real"
      printf 'dsh-update: versión '
      "$NODE_BIN" --expose-internals "$real" -V || true
      printf 'dsh-update: `dsh` usa desde ahora la versión más alta disponible.\n'

      # El parche del panel vive en el bundle instalado: re-aplicarlo aquí.
      if ! "${approvalPatch}/bin/dsh-patch-approval"; then
        printf 'dsh-update: el parche del panel de aprobación no se pudo aplicar (ver arriba).\n' >&2
      fi
    '')
    approvalPatch
  ];

  # Repara el parche del panel en cada activación: idempotente y nunca
  # rompe el switch (los errores salen por stderr, no cambian el exit code).
  home.activation.dshApprovalAlways = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${approvalPatch}/bin/dsh-patch-approval --quiet || true
  '';
}
