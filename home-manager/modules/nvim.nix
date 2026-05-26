{ pkgs, pkgs-unstable, ... }:

{
  programs.neovim.enable = false;

  # 1. Empaquetamos Neovim y los plugins inestables (sin meter código Lua aquí)
  home.packages = [
    (pkgs-unstable.neovim.override {
      configure = {
        packages.myPlugins = with pkgs-unstable.vimPlugins; {
          start = [ 
            nvim-treesitter.withAllGrammars 
          ];
        };
      };
    })
  ];

  #2. Variables y Alias
  home.shellAliases = {
    vi = "nvim";
    vimdiff = "nvim -d";
  };
}