{ pkgs, ... }: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}

