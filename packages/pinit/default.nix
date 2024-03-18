{
  pkgs,
  lib,
}: let
  packageName = "pinit";
in
  pkgs.stdenv.mkDerivation rec {
    name = packageName;
    src = ./.;

    buildInputs = with pkgs; [
      cargo
    ];

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/bin
      cp $src/${packageName}.sh $out/bin/${packageName}
      cp -r $src/src $out/bin/src
      chmod +x $out/bin/${packageName}

      wrapProgram $out/bin/${packageName} \
        --prefix PATH : ${lib.makeBinPath buildInputs}
    '';
  }
