{ pkgs, pkgsUnstable, ... }:

{
  programs.neovim.enable = false;

  # 1. Empaquetamos Neovim y los plugins inestables (sin meter código Lua aquí)
  home.packages = [
    (pkgsUnstable.neovim.override {
      configure = {
        customRC = ""; # Lo dejamos vacío deliberadamente
        packages.myPlugins = with pkgsUnstable.vimPlugins; {
          start = [ 
            nvim-treesitter.withAllGrammars 
          ];
        };
      };
    })
  ];

  # 2. Le decimos a Home Manager que tome tu init.lua y lo enlace en ~/.config/nvim/
  xdg.configFile."nvim/init.lua".source = ./init.lua;

  # 3. Variables y Alias
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}