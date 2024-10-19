{ pkgs
, lib
}:
let
  packageName = "pinit";
in
pkgs.stdenv.mkDerivation rec {
  name = packageName;
  src = ./.;

  buildInputs = with pkgs; [
    cargo
    rustc
    gcc
    git
    nix
    nodejs
    yarn
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/${packageName}.sh $out/bin/${packageName}
    chmod +x $out/bin/${packageName}

    # Substitute the src directory path with the actual path
    substituteInPlace $out/bin/${packageName} \
      --replace "src_dir=\"src\"" "src_dir=\"$src/src\""

    wrapProgram $out/bin/${packageName} \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
