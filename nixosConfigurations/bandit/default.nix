{ pkgs, ... }: {
  networking.hostName = "bandit";

  # Podman
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];

  # Firewall
  networking.firewall.enable = false;
}
