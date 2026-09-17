#===================================================================
# FREECAD (NIXOS) — Wrapper de schemas GSettings/GTK
#===================================================================
# FreeCAD crashea al arrancar con:
#   GLib-GIO-ERROR: Settings schema 'org.gtk.Settings.FileChooser' is not installed
#
# MOTIVO: FreeCAD (Qt) carga GTK3 en su proceso (vía dependencias,
# p.ej. QtWebEngine). GIO resuelve los schemas en
# $XDG_DATA_DIRS/glib-2.0/schemas, pero el wrapper de FreeCAD solo
# expone su propio share/ y el system path no deja schemas GTK
# accesibles (los guarda en share/gsettings-schemas/<pkg>, que GIO
# no escanea recursivamente).
#
# NOTA: el valor de XDG_DATA_DIRS apunta al dir gsettings-schemas
# SIN el sufijo /glib-2.0/schemas — GIO lo concatena internamente.
#
# Mismo fix que home-manager/modules/kdenlive.nix (mismo crash).
#===================================================================
{ lib, pkgs, ... }:

let
  schemaDir = pkg: "${pkg}/share/gsettings-schemas/${pkg.pname}-${pkg.version}";

  # Schemas necesarios para freecad:
  #   gsettings-desktop-schemas → org.gnome.*
  #   gtk3                     → org.gtk.Settings.FileChooser
  schemaDirs = lib.concatStringsSep ":" [
    (schemaDir pkgs.gtk3)
    (schemaDir pkgs.gsettings-desktop-schemas)
  ];

  freecad-wrapped = pkgs.symlinkJoin {
    name = "freecad-wrapped";
    paths = [
      (pkgs.writeShellScriptBin "freecad" ''
        export XDG_DATA_DIRS="${schemaDirs}:$XDG_DATA_DIRS"
        exec ${pkgs.freecad}/bin/freecad "$@"
      '')
      pkgs.freecad
    ];
  };
in {
  environment.systemPackages = [ freecad-wrapped ];
}
