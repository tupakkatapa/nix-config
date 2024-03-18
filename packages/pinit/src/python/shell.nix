{pkgs ? import <nixpkgs>}: let
  python3 = pkgs.python3;

  myPythonEnv = python3.withPackages (ps:
    with ps; [
      # other deps
    ]);
in
  pkgs.mkShell {
    buildInputs = [
      python3
      myPythonEnv
    ];

    shellHook = ''
      echo "You are now using a NIX environment for Python development"
    '';
  }
