{ pkgs
, lib
,
}:
pkgs.stdenv.mkDerivation rec {
  name = "notify-pipewire-out-switcher";
  src = ./.;

  buildInputs = with pkgs; [
    notify
    jq
    pipewire-out-switcher
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    # Assets
    mkdir -p $out/share
    cp $src/audio-volume-high-panel.svg $out/share
    cp $src/devices.json $out/share

    substituteInPlace $out/bin/${name} \
      --replace "audio-volume-high-panel.svg" "$out/share/audio-volume-high-panel.svg" \
      --replace "devices.json" "$out/share/devices.json"

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
