{ pkgs ? import <nixpkgs> { } }:
let
  myPackage = import ./default.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    myPackage
  ];

  shellHook = ''
    echo "You are now using a NIX environment"
  '';
}
