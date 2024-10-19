{ pkgs ? import <nixpkgs> { } }:
let
  package = import ./package.nix { inherit pkgs; };
in
pkgs.mkShell {
  inherit (package) buildInputs;

  shellHook = ''
    echo "You are now using a NIX environment for Python development"
  '';
}
