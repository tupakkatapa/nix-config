{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation rec {
  pname = "notify-scripts";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; [
    brightnessctl # notify-brightness
    gawk # notify-brightness
    grim # notify-screenshot
    jq # notify-not-hyprprop, notify-pipewire-out-switcher
    libnotify # all
    pamixer # notify-volume
    pipewire-out-switcher # notify-pipewire-out-switcher
    pulseaudio # notify-pipewire-out-switcher
    slurp # notify-screenshot
    xdg-utils # notify-screenshot
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/share/icons

    # Copy all assets
    cp $src/assets/*.svg $out/share/icons/
    cp $src/devices.json $out/share/

    # notify-volume
    cp $src/scripts/notify-volume.sh $out/bin/notify-volume
    chmod +x $out/bin/notify-volume
    substituteInPlace $out/bin/notify-volume \
      --replace "@ICON_HIGH@" "$out/share/icons/audio-volume-high-panel.svg" \
      --replace "@ICON_MEDIUM@" "$out/share/icons/audio-volume-medium-panel.svg" \
      --replace "@ICON_LOW@" "$out/share/icons/audio-volume-low-panel.svg" \
      --replace "@ICON_MUTED@" "$out/share/icons/audio-volume-muted-blocking-panel.svg"
    wrapProgram $out/bin/notify-volume \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # notify-brightness
    cp $src/scripts/notify-brightness.sh $out/bin/notify-brightness
    chmod +x $out/bin/notify-brightness
    substituteInPlace $out/bin/notify-brightness \
      --replace "@ICON_PATH@" "$out/share/icons/display-brightness-symbolic.svg"
    wrapProgram $out/bin/notify-brightness \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # notify-screenshot
    cp $src/scripts/notify-screenshot.sh $out/bin/notify-screenshot
    chmod +x $out/bin/notify-screenshot
    wrapProgram $out/bin/notify-screenshot \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # notify-not-hyprprop
    cp $src/scripts/notify-not-hyprprop.sh $out/bin/notify-not-hyprprop
    chmod +x $out/bin/notify-not-hyprprop
    wrapProgram $out/bin/notify-not-hyprprop \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    # notify-pipewire-out-switcher
    cp $src/scripts/notify-pipewire-out-switcher.sh $out/bin/notify-pipewire-out-switcher
    chmod +x $out/bin/notify-pipewire-out-switcher
    substituteInPlace $out/bin/notify-pipewire-out-switcher \
      --replace "@ICON_PATH@" "$out/share/icons/audio-volume-high-panel.svg" \
      --replace "@CONFIG_PATH@" "$out/share/devices.json"
    wrapProgram $out/bin/notify-pipewire-out-switcher \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    description = "A collection of notification scripts";
    license = licenses.gpl3Plus;
  };
}
