{ pkgs ? import <nixpkgs> { } }:
let
  myPackage = import ./default.nix {
    inherit pkgs;
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    myPackage
    nodejs
    yarn
  ];

  shellHook = ''
    echo "You are now using a NIX environment for Node.js development"
  '';
}
