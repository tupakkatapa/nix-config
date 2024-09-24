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
    cp $src/audio-volume-medium-panel.svg $out/share/icons
    cp $src/audio-volume-low-panel.svg $out/share/icons
    cp $src/audio-volume-muted-blocking-panel.svg $out/share/icons

    # Substitute icon paths in the script
    substituteInPlace $out/bin/${name} \
      --replace "audio-volume-high-panel.svg" "$out/share/icons/audio-volume-high-panel.svg" \
      --replace "audio-volume-medium-panel.svg" "$out/share/icons/audio-volume-medium-panel.svg" \
      --replace "audio-volume-low-panel.svg" "$out/share/icons/audio-volume-low-panel.svg" \
      --replace "audio-volume-muted-blocking-panel.svg" "$out/share/icons/audio-volume-muted-blocking-panel.svg"

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
