{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation rec {
  name = "monitor-adjust";
  src = ./.;

  buildInputs = with pkgs; [
    ddcutil
    gawk
    procps # pkill
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    cp $src/ddc-brightness.sh $out/bin/ddc-brightness
    chmod +x $out/bin/ddc-brightness

    for bin in $out/bin/*; do
      wrapProgram "$bin" \
        --prefix PATH : ${lib.makeBinPath buildInputs}
    done
  '';
}
