{ config, pkgs, pkgs-unstable, ... }:

{
  # 1. Apagamos el wrapper defectuoso de Home Manager
  programs.neovim.enable = false;

  home.packages = with pkgs; [
    # 2. El binario puro de Neovim 0.12 (Inestable)
    pkgs-unstable.neovim-unwrapped

    # 3. Herramientas base vitales (Para que Lazy compile Treesitter y Telescope)
    gcc gnumake unzip wget curl git
    ripgrep fd
    wl-clipboard xclip 

    # 4. Servidores LSP (Instalados por el sistema, consumidos por Lua)
    clang-tools   # C/C++ (clangd)
    nil           # Nix
    pyright       # Python
    rust-analyzer # Rust
    nodejs        # Requerido por algunos componentes de autocompletado
  ];

  # 5. Enlace a tu carpeta local de dotfiles (Ajusta la ruta si es necesario)
  home.file.".config/nvim".source = ../config/neovim;

  # 6. Alias
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };
}