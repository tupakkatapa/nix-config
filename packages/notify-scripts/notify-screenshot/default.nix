{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation rec {
  name = "notify-screenshot";
  src = ./.;

  buildInputs = with pkgs; [notify grim slurp];

  nativeBuildInputs = [pkgs.makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
