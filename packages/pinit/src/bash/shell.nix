{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    # deps
  ];

  shellHook = ''
    echo "You are now using a NIX environment"
  '';
}
