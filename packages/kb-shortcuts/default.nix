{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation rec {
  pname = "kb-shortcuts";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; [
    brightnessctl # brightness (laptop)
    gawk # pipewire-out-switcher, brightness
    grim # screenshot
    jq # not-hyprprop, pipewire-out-switcher
    libnotify # all
    monitor-adjust # brightness (desktop)
    pamixer # volume
    pulseaudio # pipewire-out-switcher
    slurp # screenshot
    xdg-utils # screenshot
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/share/icons

    # Copy all assets
    cp $src/assets/*.svg $out/share/icons/
    cp $src/devices.json $out/share/

    # volume
    cp $src/scripts/volume.sh $out/bin/volume
    chmod +x $out/bin/volume
    substituteInPlace $out/bin/volume \
      --replace "@ICON_HIGH@" "$out/share/icons/audio-volume-high-panel.svg" \
      --replace "@ICON_MEDIUM@" "$out/share/icons/audio-volume-medium-panel.svg" \
      --replace "@ICON_LOW@" "$out/share/icons/audio-volume-low-panel.svg" \
      --replace "@ICON_MUTED@" "$out/share/icons/audio-volume-muted-blocking-panel.svg"
    wrapProgram $out/bin/volume \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # brightness
    cp $src/scripts/brightness.sh $out/bin/brightness
    chmod +x $out/bin/brightness
    substituteInPlace $out/bin/brightness \
      --replace "@ICON_PATH@" "$out/share/icons/display-brightness-symbolic.svg"
    wrapProgram $out/bin/brightness \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # screenshot
    cp $src/scripts/screenshot.sh $out/bin/screenshot
    chmod +x $out/bin/screenshot
    wrapProgram $out/bin/screenshot \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # not-hyprprop
    cp $src/scripts/not-hyprprop.sh $out/bin/not-hyprprop
    chmod +x $out/bin/not-hyprprop
    wrapProgram $out/bin/not-hyprprop \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # pipewire-out-switcher
    cp $src/scripts/pipewire-out-switcher.sh $out/bin/pipewire-out-switcher
    chmod +x $out/bin/pipewire-out-switcher
    substituteInPlace $out/bin/pipewire-out-switcher \
      --replace "@ICON_PATH@" "$out/share/icons/audio-volume-high-panel.svg" \
      --replace "@CONFIG_PATH@" "$out/share/devices.json"
    wrapProgram $out/bin/pipewire-out-switcher \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    description = "Keyboard shortcut scripts for notifications and utilities";
    license = licenses.gpl3Plus;
  };
}
