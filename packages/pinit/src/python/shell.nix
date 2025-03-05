{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
  ];

  shellHook = ''
    echo "You are now using a NIX environment for Python development"
  '';
}
