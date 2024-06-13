{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Wine
    # winetricks
    # wineWowPackages.waylandFull
    #wineWowPackages.staging

    # Podman-compose
    podman-compose
  ];

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # VirtualBox (failed to build)
  # virtualisation.virtualbox.host = {
  #   enable = true;
  #   enableExtensionPack = true;
  # };
}
