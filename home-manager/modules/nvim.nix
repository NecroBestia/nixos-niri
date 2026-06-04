{ config, pkgs, pkgs-unstable, ... }:

let
  # 1. Agrupamos las herramientas que SOLO queremos que vea Neovim
  nvim-dependencies = with pkgs; [
    gcc gnumake unzip wget curl git ripgrep fd
    wl-clipboard xclip 
    clang-tools nil pyright rust-analyzer nodejs pkgs-unstable.tree-sitter
  ];

  # 2. Creamos nuestro propio ejecutable de Neovim aislado
  custom-neovim = pkgs.symlinkJoin {
    name = "neovim-isolated";
    paths = [ pkgs-unstable.neovim-unwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Envolvemos el binario para inyectarle un PATH exclusivo justo antes de abrirse
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${pkgs.lib.makeBinPath nvim-dependencies}
    '';
  };

in
{
  programs.neovim.enable = false;

  home.packages = [
    # 3. Instalamos ÚNICAMENTE nuestro Neovim aislado. 
    # El entorno global de tu sistema queda totalmente limpio.
    custom-neovim
  ];

  # Enlace dinámico (se mantiene igual)
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/necro/nixFlake/home-manager/config/neovim";
home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };
}
