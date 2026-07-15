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
    gcc gnumake unzip wget curl git ripgrep fd
    wl-clipboard xclip
    clang-tools nil pyright rust-analyzer nodejs pkgs-unstable.tree-sitter
    lua-language-server texlab texlive.combined.scheme-medium
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

  home.file.".config/nvim" = {
    source = ../config/neovim;
    force = true;
  };

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };

  #-----------------------------------------------------------------
  # FIX: El directorio .config/nvim es un symlink read-only del Nix store.
  #      vim.pack (Neovim 0.12+) necesita escribir nvim-pack-lock.json
  #      para sincronizar el lock data → falla con EROFS.
  #
  #      Solución: después de que HM cree los symlinks, reemplazamos
  #      nvim-pack-lock.json con una copia escribible.
  #-----------------------------------------------------------------
  home.activation.ensureWritableNvimPackLock = config.lib.dag.entryAfter ["linkGeneration"] ''
    nvim_dir="${config.home.homeDirectory}/.config/nvim"
    lock="$nvim_dir/nvim-pack-lock.json"

    # Limpia backups viejos que HM deja al regenerar el symlink
    old_backup="${config.home.homeDirectory}/.config/nvim.backup"
    if [ -e "$old_backup" ]; then
      rm -rf "$old_backup"
    fi

    # Si el directorio es un symlink, reemplazarlo con copia escribible
    if [ -h "$nvim_dir" ]; then
      echo "nvim: replacing store symlink with writable directory"
      store_path="$(readlink -f "$nvim_dir")"
      existing_lock=""
      existing_noctalia=""
      if [ -f "$lock" ]; then
        existing_lock=$(cat "$lock" 2>/dev/null)
      fi
      if [ -f "$nvim_dir/lua/noctalia.lua" ]; then
        existing_noctalia=$(cat "$nvim_dir/lua/noctalia.lua" 2>/dev/null)
      fi
      rm -f "$nvim_dir"
      cp -r "$store_path" "$nvim_dir"
      chmod -R u+w "$nvim_dir"
      if [ -n "$existing_lock" ]; then
        echo "$existing_lock" > "$lock"
        echo "nvim: preserved existing lock data"
      fi
      if [ -n "$existing_noctalia" ]; then
        echo "$existing_noctalia" > "$nvim_dir/lua/noctalia.lua"
        chmod u+w "$nvim_dir/lua/noctalia.lua"
        echo "nvim: preserved noctalia-rendered theme"
      fi
    fi

    # Asegurar que todo el arbol sea escribible (maneja casos donde HM regenera subdirs readonly)
    if [ -d "$nvim_dir" ] && [ ! -w "$nvim_dir" ]; then
      echo "nvim: fixing read-only directory"
      chmod -R u+w "$nvim_dir"
    fi
    if [ -d "$nvim_dir/lua" ] && [ ! -w "$nvim_dir/lua" ]; then
      echo "nvim: fixing read-only lua directory"
      chmod -R u+w "$nvim_dir/lua"
    fi

    if [ ! -f "$lock" ] || [ ! -w "$lock" ]; then
      echo '{"plugins":{}}' >"$lock"
      chmod u+w "$lock"
      echo "nvim-pack-lock.json: created writable lock file"
    fi
  '';
}
