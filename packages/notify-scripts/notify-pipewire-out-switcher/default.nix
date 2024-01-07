{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation rec {
  name = "notify-pipewire-out-switcher";
  src = ./.;

  buildInputs = with pkgs; [
    pulseaudio
    jq
    notify
    gawk
  ];

  nativeBuildInputs = [pkgs.makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # Assets
    mkdir -p $out/share/icons
    cp $src/audio-volume-high-panel.svg $out/share/icons

    substituteInPlace $out/bin/${name} \
      --replace "audio-volume-high-panel.svg" "$out/share/icons/audio-volume-high-panel.svg"

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # Wrapper script to execute with devices.json
    mkdir -p $out/share
    cp $src/devices.json $out/share
    echo "#!/usr/bin/env bash" > $out/bin/notify-pipewire-out-switcher-wrapper
    echo "exec $out/bin/notify-pipewire-out-switcher $out/share/devices.json" >> $out/bin/notify-pipewire-out-switcher-wrapper
    chmod +x $out/bin/notify-pipewire-out-switcher-wrapper

    wrapProgram $out/bin/notify-pipewire-out-switcher-wrapper \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
