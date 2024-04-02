{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation rec {
  pname = "tupakkatapa-utils";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; []; # Add dependencies here

  nativeBuildInputs = [pkgs.makeWrapper];

  # List of scripts to be installed
  scripts = ["cathead" "prefix" "rmc" "ns" "rpg" "lsd" "git-ffwd-update"];

  installPhase = ''
    mkdir -p $out/bin

    ${lib.concatMapStrings (name: ''
        cp ${src}/${name} $out/bin/${name}
        chmod +x $out/bin/${name}
        wrapProgram $out/bin/${name} \
          --prefix PATH : ${lib.makeBinPath buildInputs}
      '')
      scripts}
  '';

  meta = with lib; {
    description = "A collection of utility scripts by Tupakkatapa";
    homepage = "https://github.com/tupakkatapa/nix-config";
    license = licenses.gpl3Plus;
  };
}
