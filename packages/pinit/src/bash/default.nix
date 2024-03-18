{
  pkgs,
  lib,
}: let
  packageName = "foo";
in
  pkgs.stdenv.mkDerivation rec {
    name = packageName;
    src = ./.;

    buildInputs = with pkgs; [
      /*
      deps
      */
    ];

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/bin
      cp $src/${packageName}.sh $out/bin/${packageName}
      chmod +x $out/bin/${packageName}

      wrapProgram $out/bin/${packageName} \
        --prefix PATH : ${lib.makeBinPath buildInputs}
    '';
  }
