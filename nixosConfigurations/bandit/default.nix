_: {
  networking.hostName = "bandit";

  # Disable firewall
  networking.firewall.enable = false;

  imports = [
    ../.config/yubikey.nix
  ];
}
