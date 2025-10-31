{ config, pkgs, ... }:

let
  	spicePkgs = import ../path/to/spicetify-nix { inherit pkgs; };
in {
  	programs.spicetify = {
    		enable = true;
  	};
}

