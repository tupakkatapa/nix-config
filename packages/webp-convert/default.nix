{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation (finalAttrs: {
  name = "webp-convert";
  src = ./.;

  buildInputs = with pkgs; [
    libwebp
    libjpeg_turbo.bin
    gnugrep
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${finalAttrs.name}.sh $out/bin/${finalAttrs.name}
    chmod +x $out/bin/${finalAttrs.name}

    wrapProgram $out/bin/${finalAttrs.name} \
      --prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
  '';

  passthru.tests.convert = pkgs.callPackage ./test.nix { webp-convert = finalAttrs.finalPackage; };
})
