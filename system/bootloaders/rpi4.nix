# Bootloader for Raspberry Pi 4
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  boot.loader.raspberryPi = {
    enable = true;
    version = 4;
  };
  boot.loader.grub.enable = false;
}
