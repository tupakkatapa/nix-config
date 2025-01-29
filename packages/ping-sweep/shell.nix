{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    rustc
    rust-analyzer
    rustfmt
    clippy
    cargo
  ];

  shellHook = ''
    echo "You are now using a NIX environment for Rust development"
  '';
}
