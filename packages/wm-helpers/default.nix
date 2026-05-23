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
    systemd # lock-countdown (loginctl)
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
  '';

  meta = with lib; {
    description = "Window-manager helpers: lock-countdown, mem-warn, and other overlay notifiers";
    license = licenses.gpl3Plus;
  };
}
