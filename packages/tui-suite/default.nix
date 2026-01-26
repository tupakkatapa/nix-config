{ pkgs
, lib
}:
let
  manifest = (lib.importTOML ./Cargo.toml).workspace.package;
in
pkgs.rustPlatform.buildRustPackage {
  pname = "tui-suite";
  inherit (manifest) version;

  nativeBuildInputs = with pkgs; [
    pkg-config
    makeWrapper
  ];

  buildInputs = with pkgs; [
    alsa-lib # mustui (rodio audio)
    dbus # blutui, nettui (D-Bus)
  ];

  postInstall = ''
    wrapProgram $out/bin/voltui \
      --prefix PATH : ${lib.makeBinPath [ pkgs.pulseaudio ]}
    wrapProgram $out/bin/blutui \
      --prefix PATH : ${lib.makeBinPath [ pkgs.bluez pkgs.systemd ]}
    wrapProgram $out/bin/nettui \
      --prefix PATH : ${lib.makeBinPath [ pkgs.systemd pkgs.iwd ]}
  '';

  src = lib.sourceByRegex ./. [
    "^Cargo.toml$"
    "^Cargo.lock$"
    "^packages.*$"
  ];

  cargoLock.lockFile = ./Cargo.lock;
}
