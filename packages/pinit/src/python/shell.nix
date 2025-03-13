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
    python3
  ];

  shellHook = ''
    echo "You are now using a NIX environment for Python development"
  '';
}
