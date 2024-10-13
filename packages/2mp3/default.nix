{ pkgs
, lib
,
}:
let
  packageName = "2mp3";
in
pkgs.stdenv.mkDerivation rec {
  name = packageName;
  src = ./.;

  buildInputs = with pkgs; [
    python3
    ffmpeg
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/main.py $out/bin/${packageName}
    chmod +x $out/bin/${packageName}

    wrapProgram $out/bin/${packageName} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
