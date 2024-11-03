{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation rec {
  name = "notify-brightness";
  src = ./.;

  buildInputs = with pkgs; [
    notify
    ddcutil
    monitor-adjust
    gawk
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    # Assets
    mkdir -p $out/share/icons
    cp $src/display-brightness-symbolic.svg $out/share/icons

    # Substitute icon path in script
    substituteInPlace $out/bin/${name} \
      --replace "@ICON_PATH@" "$out/share/icons/display-brightness-symbolic.svg"

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
