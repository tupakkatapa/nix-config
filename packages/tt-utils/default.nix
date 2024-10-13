{ pkgs
, lib
,
}:
pkgs.stdenv.mkDerivation rec {
  pname = "tt-utils";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; [
    coreutils # various
    gawk # yt-sub, git-ffwd-update
    git # git-ffwd-update
    nix # ns
    gnused # yt-sub, prefix
    zstd # raidgrep
    parallel # raidgrep
    curl # filemon
    libnotify # filemon
    yt-dlp # yt-sub
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  # List of scripts to be installed
  scripts = [
    "cathead"
    "prefix"
    "rmc"
    "ns"
    "rpg"
    "lsd"
    "git-ffwd-update"
    "myip"
    "filemon"
    "raidgrep"
    "yt-sub"
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
