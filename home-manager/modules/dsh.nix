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
# node no lo permite vía NODE_OPTIONS, así que el wrapper resuelve
# el binario real de dsh y lo ejecuta directamente con el flag.
#
# Primer uso descarga el paquete a ~/.npm (necesita red);
# después usa la caché de npx (~/.npm/_npx).
#===================================================================
{ pkgs, ... }:
let
  nodejs = pkgs.nodejs_24;
in {
  home.packages = [
    (pkgs.writeShellScriptBin "dsh" ''
      export PATH="${nodejs}/bin:$PATH"
      bin="$(npx --yes -p @deepseek-ai/dsh -c 'command -v dsh' 2>/dev/null | tail -1)"
      real="$(readlink -f "$bin")"
      exec "${nodejs}/bin/node" --expose-internals "$real" "$@"
    '')
  ];
}
