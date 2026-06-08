{ pkgs, ... }:
{
  # Run pre-built dynamic ELFs from outside the store (uv, LSPs, vendor tools).
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      glibc
    ];
  };
}
