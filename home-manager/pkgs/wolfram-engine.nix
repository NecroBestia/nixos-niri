{ pkgs }:
pkgs.wolfram-engine.overrideAttrs (old: {
  version = "15.0.0";
  src = pkgs.requireFile {
    name = "WolframEngine_15_LIN.sh";
    hash = "sha256-U1LR5UTbdCqa5JN3DluH4Iq7YF+KfZbZx35YVVHAMu4=";
    message = ''
      This nix expression requires that WolframEngine_15_LIN.sh is
      already part of the store. Download the file from
      https://www.wolfram.com/engine/ and add it to the nix store
      with nix-store --add-fixed sha256 <FILE>.
    '';
  };
  installPhase = builtins.replaceStrings
    [ "for path in MathKernel math mcc wolfram; do" ]
    [ "for path in MathKernel math mcc wolfram; do\n      [ -e \"$path\" ] || continue" ]
    old.installPhase;
})
