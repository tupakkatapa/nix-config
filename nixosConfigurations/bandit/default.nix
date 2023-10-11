{
  pkgs,
  lib,
  config,
  ...
}: {
  # Bootloader for x86_64-linux / aarch64-linux
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Localization and basic stuff
  networking.hostName = "bandit";
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";
  console.keyMap = "fi";

  # Strict SSH settings
  services.openssh = {
    enable = true;
    allowSFTP = false;
    extraConfig = ''
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding yes
      AuthenticationMethods publickey
      X11Forwarding no
    '';
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
}
