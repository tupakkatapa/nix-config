{ pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  name = "dm-main";
  src = ./.;

  buildInputs = with pkgs; [
    coreutils
    findutils
    firefox
    gawk
    gnugrep
    gnused
    jq
    sqlite
    wofi
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/dm-main.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    # Assets
    mkdir -p $out/share
    cp $src/shortcuts.json $out/share

    substituteInPlace $out/bin/${name} \
      --replace "@SHORTCUTS_FILE_PATH@" "$out/share/shortcuts.json"

    # Wrapping the program to include dependencies in PATH
    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
