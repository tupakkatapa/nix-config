{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation rec {
  name = "dm-radio";
  src = ./.;

  buildInputs = with pkgs; [
    wofi
    notify
    mpv
    jq
  ];

  nativeBuildInputs = [pkgs.makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # Wrapper script to execute with stations.json
    mkdir -p $out/share
    cp $src/stations.json $out/share
    echo "#!/usr/bin/env bash" > $out/bin/dm-radio-wrapper
    echo "exec $out/bin/dm-radio $out/share/stations.json" >> $out/bin/dm-radio-wrapper
    chmod +x $out/bin/dm-radio-wrapper

    wrapProgram $out/bin/dm-radio-wrapper \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
