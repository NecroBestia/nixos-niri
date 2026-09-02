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
#     rust-analyzer (Rust), lua_ls (Lua), texlab (LaTeX), tree-sitter
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
  nvim-dependencies = with pkgs; [
    gcc gnumake unzip curl git ripgrep fd               # wget removido: curl ya cubre descargas.
    wl-clipboard                                           # xclip removido: no útil en Wayland.
    clang-tools nil pyright rust-analyzer pkgs-unstable.tree-sitter # nodejs removido: no necesario para LSPs.
    lua-language-server texlab zathura texlive.combined.scheme-full # zathura: visor PDF para vimtex (forward/backward search)
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
    ".config/nvim/lua/matugen.lua"     = { source = ../config/neovim/lua/matugen.lua;     force = true; };
    ".config/nvim/lua/core/keymaps.lua"     = { source = ../config/neovim/lua/core/keymaps.lua;     force = true; };
    ".config/nvim/lua/core/lsp.lua"         = { source = ../config/neovim/lua/core/lsp.lua;         force = true; };
    ".config/nvim/lua/core/options.lua"     = { source = ../config/neovim/lua/core/options.lua;     force = true; };
    ".config/nvim/lua/core/treesitter.lua"  = { source = ../config/neovim/lua/core/treesitter.lua; force = true; };
    ".config/nvim/lua/pack/commands.lua"    = { source = ../config/neovim/lua/pack/commands.lua;    force = true; };
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
