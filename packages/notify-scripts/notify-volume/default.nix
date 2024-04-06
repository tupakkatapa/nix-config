{ pkgs
, lib
,
}:
pkgs.stdenv.mkDerivation rec {
  name = "notify-volume";
  src = ./.;

  buildInputs = with pkgs; [ notify pamixer ];

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    # Assets
    mkdir -p $out/share/icons
    cp $src/audio-volume-high-panel.svg $out/share/icons

    substituteInPlace $out/bin/${name} \
      --replace "audio-volume-high-panel.svg" "$out/share/icons/audio-volume-high-panel.svg"

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
