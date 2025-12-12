{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation rec {
  pname = "dm-scripts";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; [
    jq # dm-radio
    libnotify # all
    mpv # dm-radio
    pulseaudio # dm-pipewire-out-switcher
    wofi # all
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/share

    # Copy assets
    cp $src/stations.json $out/share/

    # dm-radio
    cp $src/scripts/dm-radio.sh $out/bin/dm-radio
    chmod +x $out/bin/dm-radio
    substituteInPlace $out/bin/dm-radio \
      --replace "@STATIONS_FILE@" "$out/share/stations.json"
    wrapProgram $out/bin/dm-radio \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # dm-pipewire-out-switcher
    cp $src/scripts/dm-pipewire-out-switcher.sh $out/bin/dm-pipewire-out-switcher
    chmod +x $out/bin/dm-pipewire-out-switcher
    wrapProgram $out/bin/dm-pipewire-out-switcher \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    description = "A collection of wofi/dmenu scripts";
    license = licenses.gpl3Plus;
  };
}
