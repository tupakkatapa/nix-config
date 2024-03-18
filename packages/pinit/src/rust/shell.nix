{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    rustc
    cargo
    # other deps
  ];

  shellHook = ''
    echo "You are now using a NIX environment for Rust development"
  '';
}
