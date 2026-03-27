_: {
  networking.hostName = "bandit";

  # Disable firewall
  networking.firewall.enable = false;

  imports = [
    ../.config/hw/yubikey.nix
  ];
}
