# build: nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'
{
  stdenv,
  rustPlatform,
  lib,
  pkgs,
}: let
  manifest = (lib.importTOML ./Cargo.toml).package;
  movieQuotesJson = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/prasertcbs/basic-dataset/6465abb15f76b9ad22babca35f06ba4a01021917/movie_quotes.json";
    sha256 = "sha256-9qNt3CDiFd91uPa/C2/Dv/x9CrrKW08i2QOL2Y+2pjA=";
  };
in
  rustPlatform.buildRustPackage rec {
    pname = manifest.name;
    version = manifest.version;
    cargoLock.lockFile = ./Cargo.lock;
    src = lib.cleanSource ./.;

    postUnpack = ''
      cp ${movieQuotesJson} $sourceRoot/src/movie-quotes.json
    '';
  }
