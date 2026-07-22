#===================================================================
# SIOYEK — PDF Reader con Qt/XCB (fix NVIDIA Wayland)
#===================================================================
# Envuelve sioyek para forzar QT_QPA_PLATFORM=xcb porque
# QOpenGLWidget falla con el driver NVIDIA en Wayland:
#   QEGLPlatformContext: Failed to create context: 3009
#
# El error (EGL_BAD_MATCH) ocurre incluso con egl-wayland instalado
# debido a incompatibilidad entre Qt 5 y NVIDIA EGLStreams.
#
# XCB funciona correctamente y no afecta al rendimiento del visor.
#===================================================================
{ pkgs, ... }:
let
  sioyek-wrapped = pkgs.symlinkJoin {
    name = "sioyek-wrapped";
    paths = [ pkgs.sioyek ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/sioyek \
        --set QT_QPA_PLATFORM xcb
    '';
  };
in {
  home.packages = [ sioyek-wrapped ];
}
