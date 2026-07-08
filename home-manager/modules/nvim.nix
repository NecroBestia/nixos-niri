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
#     rust-analyzer (Rust), tree-sitter
#   - Utilidades: ripgrep, fd (búsqueda), curl, git
#   - Portapapeles: wl-clipboard, xclip
#
# gestión de plugins: vim.pack (nativo de Neovim 0.11+).
# Los plugins se definen en lua/pack/sources.lua y se cachean
# en nvim-pack-lock.json.
#
# NOTA: La ruta del symlink es absoluta (mkOutOfStoreSymlink).
# Si se mueve el flake, actualizar la ruta.
#===================================================================
{ config, pkgs, pkgs-unstable, ... }:

let
  nvim-dependencies = with pkgs; [
    gcc gnumake unzip wget curl git ripgrep fd
    wl-clipboard xclip
    clang-tools nil pyright rust-analyzer nodejs pkgs-unstable.tree-sitter
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

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/home/necro/nixFlake/home-manager/config/neovim";

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };
}
