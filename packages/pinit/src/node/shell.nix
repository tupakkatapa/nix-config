{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    yarn
  ];

  shellHook = ''
    echo "You are now using a NIX environment for Node.js development"
  '';
}

