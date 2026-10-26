{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation rec {
  pname = "wm-helpers";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; [
    hyprland # lock-countdown (hyprctl cursorpos)
    libnotify # all
    procps # lock-countdown (pgrep)
    jq # float-on-title (monitor geometry)
    socat # float-on-title (socket2)
    systemd # lock-countdown (loginctl)
    util-linux # float-on-title (logger)
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin

    cp $src/scripts/lock-countdown.sh $out/bin/lock-countdown
    chmod +x $out/bin/lock-countdown
    wrapProgram $out/bin/lock-countdown \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    cp $src/scripts/mem-warn.sh $out/bin/mem-warn
    chmod +x $out/bin/mem-warn
    wrapProgram $out/bin/mem-warn \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    cp $src/scripts/bat-warn.sh $out/bin/bat-warn
    chmod +x $out/bin/bat-warn
    wrapProgram $out/bin/bat-warn \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    cp $src/scripts/float-on-title.sh $out/bin/float-on-title
    chmod +x $out/bin/float-on-title
    wrapProgram $out/bin/float-on-title \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    description = "Window-manager helpers: lock-countdown, mem-warn, bat-warn, float-on-title";
    license = licenses.gpl3Plus;
  };
}
