{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation (finalAttrs: {
  name = "tpm-host-key";
  src = ./.;

  buildInputs = with pkgs; [
    coreutils
    tpm2-tools
    unixtools.xxd
    (python3.withPackages (p: [ p.cryptography ]))
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${finalAttrs.name}.sh $out/bin/${finalAttrs.name}
    chmod +x $out/bin/${finalAttrs.name}

    wrapProgram $out/bin/${finalAttrs.name} \
      --prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
  '';

  passthru.tests.derive = pkgs.callPackage ./test.nix { tpm-host-key = finalAttrs.finalPackage; };
  meta.mainProgram = finalAttrs.name;
})
