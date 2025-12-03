{ lib
, stdenv
, makeWrapper
, coreutils
, gnugrep
, gawk
, bc
, nix
}:

stdenv.mkDerivation {
  pname = "dep-hunter";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp hunt-large-deps.sh $out/bin/dep-hunter
    chmod +x $out/bin/dep-hunter

    wrapProgram $out/bin/dep-hunter \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        gnugrep
        gawk
        bc
        nix
      ]}
  '';

  meta = with lib; {
    description = "Find large dependencies in NixOS closures";
    longDescription = ''
      Automated tool to analyze NixOS package closures and list all large
      dependencies with their dependency chains. Helps optimize closure size
      and identify candidates for package overrides or runtime-modules.
    '';
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
