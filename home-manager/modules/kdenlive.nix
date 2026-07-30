{ lib, pkgs, pkgs-unstable, ... }:
let
  schemaDir = pkg: "${pkg}/share/gsettings-schemas/${pkg.pname}-${pkg.version}";

  # Schemas necesarios para kdenlive:
  #   gsettings-desktop-schemas → org.gnome.*
  #   gtk3                     → org.gtk.Settings.FileChooser (necesario tras init OpenGL)
  schemaDirs = lib.concatStringsSep ":" [
    (schemaDir pkgs-unstable.gsettings-desktop-schemas)
    (schemaDir pkgs-unstable.gtk3)
  ];

  kdenlive-wrapped = pkgs.symlinkJoin {
    name = "kdenlive-wrapped";
    paths = [
      (pkgs.writeShellScriptBin "kdenlive" ''
        export XDG_DATA_DIRS="${schemaDirs}:$XDG_DATA_DIRS"
        exec ${pkgs-unstable.kdePackages.kdenlive}/bin/kdenlive "$@"
      '')
      (pkgs.writeShellScriptBin "kdenlive_render" ''
        export XDG_DATA_DIRS="${schemaDirs}:$XDG_DATA_DIRS"
        exec ${pkgs-unstable.kdePackages.kdenlive}/bin/kdenlive_render "$@"
      '')
      pkgs-unstable.kdePackages.kdenlive
    ];
  };
in {
  home.packages = [ kdenlive-wrapped ];
}
