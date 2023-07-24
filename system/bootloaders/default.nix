# Bootloader for x86_64-linux / aarch64-linux
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
