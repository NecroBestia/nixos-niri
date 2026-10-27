#===================================================================
# NEOVIM — Editor Aislado con LSPs
#===================================================================
# Neovim envuelto en un binario aislado:
#   - Las herramientas de desarrollo (clangd, rust-analyzer, etc.)
#     SOLO están en el PATH de Neovim, no contaminan el sistema.
#   - El wrapper inyecta las dependencias vía makeWrapper.
#
# DEPENDENCIAS INCLUIDAS:
#   - Compilación: gcc, gnumake, unzip
#   - LSPs: clangd (C/C++), nil (Nix), pyright (Python),
#     rust-analyzer (Rust), lua_ls (Lua), texlab (LaTeX), tree-sitter,
#     ruff (Python lint/formato), sqls (SQL),
#     prolog_ls (Prolog, pack lsp_server VENDADO más abajo),
#     hls (Haskell)
#   - Formatters: clang-format (en clang-tools), rustfmt (Rust),
#     sqlfluff (SQL, CLI), ormolu (Haskell, usado por HLS),
#     y los CLI de conform.nvim: nixfmt-rfc-style, stylua, tex-fmt,
#     shfmt, gofmt (pkg go), google-java-format, taplo, prettier,
#     racket (raco fmt) y wrappers propios de pkgs: cl-indentify
#     (Common Lisp) y prolog-formatter (Prolog stdout, definidos abajo).
#   - Utilidades: ripgrep, fd (búsqueda), curl, git
#   - Portapapeles: wl-clipboard, xclip
#
# Configuración: home-manager/config/nvim/ (init.lua + lua/core/ +
# lua/plugins/). La lista fuente vive en config/nvim/lua/plugins.lua
# y vim.pack cachea en nvim-pack-lock.json (gestionado en caliente).
#
# NOTA: La ruta es relativa al flake. Editar los archivos en
# config/neovim/ requiere ejecutar home-manager switch para
# que los cambios tomen efecto.
#===================================================================
{ config, pkgs, pkgs-unstable, ... }:

let
  # cl-indentify (Common Lisp) — CLI sobre la librería de nixpkgs.
  # nixpkgs trae sbclPackages.cl-indentify pero no su CLI: upstream lo
  # distribuye vía roswell y el sistema "cl-indentify/cli" depende de
  # command-line-arguments, que nixpkgs no empaqueta. Este wrapper llama
  # directo a la librería: stdin → stdout (lo que conform.nvim espera).
  #
  # ASDF busca los .asd recorriendo cada entrada; "//" = recursivo.
  # (El setup-hook de lisp-modules está desactivado en nixpkgs, así que
  # el registro se construye explícitamente.)
  clSourceRegistry = pkgs.lib.concatMapStringsSep ":" (p: "${p}//") [
    pkgs.sbclPackages.cl-indentify
    pkgs.sbclPackages.alexandria
    pkgs.sbclPackages.trivial-gray-streams
  ];

  cl-indentify = pkgs.stdenv.mkDerivation {
    pname = "cl-indentify";
    version = "0.1";

    dontUnpack = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    buildInputs = [
      pkgs.sbclPackages.cl-indentify
      pkgs.sbclPackages.alexandria
      pkgs.sbclPackages.trivial-gray-streams
    ];

    installPhase = ''
      mkdir -p $out/bin $out/share/cl-indentify

      cat > $out/share/cl-indentify/format.lisp <<'LISP'
      (require "asdf")
      ;; Los .fasl ya vienen precompilados al lado de los fuentes en el
      ;; store; sin esto ASDF recompila en ~/.cache y ensucia stdout.
      (asdf:disable-output-translations)
      (asdf:load-system "cl-indentify")
      (indentify:initialize-templates)
      (indentify:indentify)
      LISP

      makeWrapper ${pkgs.sbcl}/bin/sbcl $out/bin/cl-indentify \
        --prefix CL_SOURCE_REGISTRY : "${clSourceRegistry}" \
        --add-flags "--noinform --non-interactive --disable-debugger" \
        --add-flags "--load $out/share/cl-indentify/format.lisp"
    '';

    meta = {
      description = "Automatic indentation for Common Lisp (stdin/stdout CLI)";
      homepage = "https://github.com/yitzchak/cl-indentify";
      license = pkgs.lib.licenses.mit;
      mainProgram = "cl-indentify";
    };
  };

  # Pack lsp_server vendado (jamesnvc/lsp_server) — LSP y formatter de
  # Prolog. No viene con el swi-prolog de nixpkgs y no se usa
  # `swipl pack install` por ser impuro (escribe el home). Se hace
  # symlink read-only bajo share/swi-prolog/pack; SWI resuelve
  # library(lsp_server) vía XDG_DATA_DIRS, que se inyecta solo en el
  # wrapper de nvim (fuera de nvim el sistema queda intacto).
  lsp-server-src = pkgs.fetchFromGitHub {
    owner = "jamesnvc";
    repo = "lsp_server";
    rev = "d5f30d69c151494c24feef6bff06e60a4f919fc7";
    hash = "sha256-5oe0JmhPhsOFirTGXa8jOBgbBWvgTDvTtUeI8uDzeX8=";
  };

  lsp-server-pack = pkgs.runCommand "swipl-pack-lsp_server" { } ''
    install -d $out/share/swi-prolog/pack
    ln -s ${lsp-server-src} $out/share/swi-prolog/pack/lsp_server
  '';

  # prolog-formatter (stdin→stdout para conform): el app `swipl formatter`
  # del pack funciona in-place por defecto y su argv no acepta flags
  # desde el CLI clásico ("Unknown option: -i"). Este wrapper replica
  # la cláusula stdout de app/formatter.pl: search-path lsp → prolog/
  # del pack vendado + file_formatted/2 y emit_reified/2 a stdout.
  # El contenido llega por stdin a un temp file (el camino que conform
  # usa con stdin=true) y el nombre via env (sin problemas de quoting).
  prolog-formatter = pkgs.writeShellScriptBin "prolog-formatter" ''
    tmp=$(mktemp "''${TMPDIR:-/tmp}/prolog-formatter.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    cat > "$tmp"
    export PROLOG_FMT_FILE="$tmp"
    exec ${pkgs-unstable.swi-prolog}/bin/swipl -q -t halt \
      -g "asserta(user:file_search_path(lsp, '${lsp-server-src}/prolog'))" \
      -g "use_module(lsp(lsp_formatter), [file_formatted/2])" \
      -g "use_module(lsp(lsp_formatter_parser), [emit_reified/2])" \
      -g "getenv('PROLOG_FMT_FILE', F), file_formatted(F, FF), emit_reified(user_output, FF)"
  '';

  nvim-dependencies = with pkgs; [
    gcc gnumake unzip curl git ripgrep fd               # wget removido: curl ya cubre descargas.
    wl-clipboard                                           # xclip removido: no útil en Wayland.
    clang-tools nil pyright rust-analyzer pkgs-unstable.tree-sitter # nodejs removido: no necesario para LSPs.
    lua-language-server texlab zathura texlive.combined.scheme-full # zathura: visor PDF para vimtex (forward/backward search)
    # LSPs y formatters adicionales (unstable, ver decisión de rama en shared):
    pkgs-unstable.ruff                   # Python: LSP nativo (lint + formato)
    pkgs-unstable.rustfmt                # Rust: formatter requerido por rust-analyzer
    pkgs-unstable.sqls                   # SQL: LSP (compleción/navegación)
    pkgs-unstable.sqlfluff               # SQL: formatter CLI (fallback de <leader>f)
    pkgs-unstable.swi-prolog             # Prolog: LSP via prolog_ls (pack lsp_server vendado)
    pkgs-unstable.haskell-language-server # Haskell: LSP (hls)
    pkgs-unstable.ormolu                 # Haskell: formatter usado por HLS
    # Formatters CLI para conform.nvim (ver lua/pack/conform.lua):
    nixfmt-rfc-style                     # Nix (RFC 166)
    stylua                               # Lua
    tex-fmt                              # LaTeX (rápido; latexindent ya viene en texlive)
    shfmt                                # Shell (sh/bash/zsh)
    go                                   # Go (gofmt)
    google-java-format                   # Java
    taplo                                # TOML
    prettier                             # Markdown/JS/TS/JSON/YAML/CSS/HTML
    racket                               # Racket (raco fmt; requiere `raco pkg install fmt`)
    cl-indentify                         # Common Lisp (definido arriba, ver clSourceRegistry)
    prolog-formatter                     # Prolog stdout (definido arriba, requiere lsp-server-src)
  ];

  custom-neovim = pkgs.symlinkJoin {
    name = "neovim-isolated";
    paths = [ pkgs-unstable.neovim-unwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${pkgs.lib.makeBinPath nvim-dependencies} \
        --prefix XDG_DATA_DIRS : ${lsp-server-pack}/share
    '';
  };

in {
  programs.neovim.enable = false;  # Desactiva el Neovim de HM (usamos el wrapper).

  home.packages = [
    custom-neovim
  ];

  home.file = {
    # Archivos individuales en vez de .config/nvim completo para evitar
    # colisiones en checkLinkTargets cuando el directorio ya existe.
    # Config viviendo en config/nvim/ (la carpeta vieja config/neovim/
    # queda en el repo como respaldo).
    ".config/nvim/init.lua"                 = { source = ../config/nvim/init.lua;                 force = true; };
    # nvim-pack-lock.json NO se despliega vía HM — vim.pack lo crea y
    # gestiona como archivo escribible en caliente. Si HM lo desplegara
    # sería un symlink read-only → EROFS al escribir.
    # lua/noctalia.lua tampoco se despliega: lo genera la plantilla de
    # Noctalia (config/noctalia/templates/nvim-base16.lua) en caliente.
    ".config/nvim/lua/core/options.lua"     = { source = ../config/nvim/lua/core/options.lua;     force = true; };
    ".config/nvim/lua/core/filetypes.lua"   = { source = ../config/nvim/lua/core/filetypes.lua;   force = true; };
    ".config/nvim/lua/core/autocmds.lua"    = { source = ../config/nvim/lua/core/autocmds.lua;    force = true; };
    ".config/nvim/lua/core/keymaps.lua"     = { source = ../config/nvim/lua/core/keymaps.lua;     force = true; };
    ".config/nvim/lua/core/lsp.lua"         = { source = ../config/nvim/lua/core/lsp.lua;         force = true; };
    ".config/nvim/lua/core/treesitter.lua"  = { source = ../config/nvim/lua/core/treesitter.lua;  force = true; };
    ".config/nvim/lua/plugins.lua"          = { source = ../config/nvim/lua/plugins.lua;          force = true; };
    ".config/nvim/lua/plugins/commands.lua"   = { source = ../config/nvim/lua/plugins/commands.lua;   force = true; };
    ".config/nvim/lua/plugins/editor.lua"     = { source = ../config/nvim/lua/plugins/editor.lua;     force = true; };
    ".config/nvim/lua/plugins/ui.lua"         = { source = ../config/nvim/lua/plugins/ui.lua;         force = true; };
    ".config/nvim/lua/plugins/completion.lua" = { source = ../config/nvim/lua/plugins/completion.lua; force = true; };
    ".config/nvim/lua/plugins/git.lua"        = { source = ../config/nvim/lua/plugins/git.lua;        force = true; };
    ".config/nvim/lua/plugins/latex.lua"      = { source = ../config/nvim/lua/plugins/latex.lua;      force = true; };
    ".config/nvim/lua/plugins/focus.lua"      = { source = ../config/nvim/lua/plugins/focus.lua;      force = true; };
    ".config/nvim/lua/plugins/markdown.lua"   = { source = ../config/nvim/lua/plugins/markdown.lua;   force = true; };
    ".config/nvim/lua/plugins/format.lua"     = { source = ../config/nvim/lua/plugins/format.lua;     force = true; };
  };

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };


}
