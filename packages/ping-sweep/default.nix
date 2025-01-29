{ rustPlatform
, lib
}:
let
  manifest = (lib.importTOML ./Cargo.toml).package;
in
rustPlatform.buildRustPackage {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.sourceByRegex ./. [
    "^Cargo.toml$"
    "^Cargo.lock$"
    "^example.toml$"
    "^src.*$"
  ];

  cargoLock.lockFile = ./Cargo.lock;
}
