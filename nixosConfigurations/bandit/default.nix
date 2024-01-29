{
  pkgs,
  lib,
  config,
  ...
}: {
  networking.hostName = "bandit";

  # Autologin for 'kari'
  services.getty.autologinUser = "kari";

  # Allow passwordless sudo from wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
    execWheelOnly = true;
  };

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
