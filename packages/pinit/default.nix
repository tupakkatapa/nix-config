{ pkgs
, lib
,
}:
let
  packageName = "pinit";
in
pkgs.stdenv.mkDerivation rec {
  name = packageName;
  src = ./.;

  buildInputs = with pkgs; [
    cargo
    git
    nix
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/${packageName}.sh $out/bin/${packageName}
    chmod +x $out/bin/${packageName}

    substituteInPlace $out/bin/${packageName} \
      --replace "src" "$src/src"

    wrapProgram $out/bin/${packageName} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
