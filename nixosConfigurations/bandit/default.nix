{
  pkgs,
  lib,
  config,
  ...
}: {
  networking.hostName = "bandit";

  # No bootloader
  boot.loader.grub.enable = false;

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
