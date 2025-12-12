{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation rec {
  pname = "tt-utils";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; [
    coreutils # cathead
    curl # filemon
    findutils # cathead, raidgrep
    gnused # prefix
    libnotify # filemon
    parallel # raidgrep
    zstd # raidgrep
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  # List of scripts to be installed
  scripts = [
    "cathead"
    "prefix"
    "rmc"
    "filemon"
    "raidgrep"
  ];

  installPhase = ''
    mkdir -p $out/bin

    ${lib.concatMapStrings (name: ''
        cp ${src}/scripts/${name} $out/bin/${name}
        chmod +x $out/bin/${name}
        wrapProgram $out/bin/${name} \
          --prefix PATH : ${lib.makeBinPath buildInputs}
      '')
      scripts}
  '';

  meta = with lib; {
    description = "A collection of utility scripts by Tupakkatapa";
    homepage = "https://github.com/tupakkatapa/nix-config";
    license = licenses.gpl3Plus;
  };
}
