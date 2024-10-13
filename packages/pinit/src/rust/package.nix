{ rustPlatform
, lib
,
}:
let
  manifest = (lib.importTOML ./Cargo.toml).package;
in
rustPlatform.buildRustPackage {
  pname = manifest.name;
  inherit (manifest) version;
  cargoLock.lockFile = ./Cargo.lock;
  src = lib.cleanSource ./.;
}
