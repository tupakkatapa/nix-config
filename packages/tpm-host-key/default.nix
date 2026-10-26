{ pkgs
, lib
}:
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "tpm-host-key";
  version = "0.1";
  src = ./.;

  buildInputs = with pkgs; [
    coreutils
    tpm2-tools
    unixtools.xxd
    openssl
  ];

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/${finalAttrs.pname}.sh $out/bin/${finalAttrs.pname}
    chmod +x $out/bin/${finalAttrs.pname}

    wrapProgram $out/bin/${finalAttrs.pname} \
      --prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
  '';

  passthru.tests.derive = pkgs.callPackage ./test.nix { tpm-host-key = finalAttrs.finalPackage; };
  meta.mainProgram = finalAttrs.pname;
})
