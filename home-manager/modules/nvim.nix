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
#     ruff (Python lint/formato), sqls (SQL), prolog_ls (Prolog vía SWI),
#     hls (Haskell)
#   - Formatters: clang-format (en clang-tools), rustfmt (Rust),
#     sqlfluff (SQL, CLI), ormolu (Haskell, usado por HLS),
#     y los CLI de conform.nvim: nixfmt-rfc-style, stylua, tex-fmt,
#     shfmt, gofmt (pkg go), google-java-format, taplo, prettier,
#     racket (raco fmt) y cl-indentify (wrapper propio, pkgs/).
#   - Utilidades: ripgrep, fd (búsqueda), curl, git
#   - Portapapeles: wl-clipboard, xclip
#
# gestión de plugins: vim.pack (nativo de Neovim 0.11+).
# Los plugins se definen en lua/pack/sources.lua y se cachean
# en nvim-pack-lock.json.
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
    pkgs-unstable.swi-prolog             # Prolog: LSP via prolog_ls (library(lsp_server))
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
  ];

  custom-neovim = pkgs.symlinkJoin {
    name = "neovim-isolated";
    paths = [ pkgs-unstable.neovim-unwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${pkgs.lib.makeBinPath nvim-dependencies}
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
    ".config/nvim/init.lua"            = { source = ../config/neovim/init.lua;            force = true; };
    # nvim-pack-lock.json NO se despliega vía HM — vim.pack lo crea y
    # gestiona como archivo escribible en caliente. Si HM lo desplegara
    # sería un symlink read-only → EROFS al escribir.
    # lua/noctalia.lua tampoco se despliega: lo genera la plantilla de
    # Noctalia (config/noctalia/templates/nvim-base16.lua) en caliente.
    ".config/nvim/lua/core/keymaps.lua"     = { source = ../config/neovim/lua/core/keymaps.lua;     force = true; };
    ".config/nvim/lua/core/lsp.lua"         = { source = ../config/neovim/lua/core/lsp.lua;         force = true; };
    ".config/nvim/lua/core/options.lua"     = { source = ../config/neovim/lua/core/options.lua;     force = true; };
    ".config/nvim/lua/core/treesitter.lua"  = { source = ../config/neovim/lua/core/treesitter.lua; force = true; };
    ".config/nvim/lua/pack/commands.lua"    = { source = ../config/neovim/lua/pack/commands.lua;    force = true; };
    ".config/nvim/lua/pack/conform.lua"     = { source = ../config/neovim/lua/pack/conform.lua;     force = true; };
    ".config/nvim/lua/pack/init.lua"        = { source = ../config/neovim/lua/pack/init.lua;        force = true; };
    ".config/nvim/lua/pack/mini.lua"        = { source = ../config/neovim/lua/pack/mini.lua;        force = true; };
    ".config/nvim/lua/pack/plugins.lua"     = { source = ../config/neovim/lua/pack/plugins.lua;     force = true; };
    ".config/nvim/lua/pack/sources.lua"     = { source = ../config/neovim/lua/pack/sources.lua;     force = true; };
    ".config/nvim/lua/pack/vimtex.lua"      = { source = ../config/neovim/lua/pack/vimtex.lua;      force = true; };
  };

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };


}
