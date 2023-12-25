# build: nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'
{
  stdenv,
  rustPlatform,
  lib,
}: let
  manifest = (lib.importTOML ./Cargo.toml).package;
in
  rustPlatform.buildRustPackage rec {
    pname = manifest.name;
    version = manifest.version;
    cargoLock.lockFile = ./Cargo.lock;
    src = lib.cleanSource ./.;
  }
