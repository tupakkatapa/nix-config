{ ... }: {
  networking.hostName = "bandit";

  # Disable firewall
  networking.firewall.enable = false;

  imports = [
    ../.config/hw/yubikey.nix
  ];

  # No agenix here, so there is no password to prompt for
  security.sudo.extraRules = [{
    users = [ "core" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
