_: {
  imports = [
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ../.config/yubikey.nix
    ./hardware-configuration.nix
  ];

  # Set local flake path to be able to be referenced
  environment.variables.FLAKE_DIR = "/home/kari/nix-config";

  # Bootloader for x86_64-linux / aarch64-linux
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;

  # Connectivity
  networking = {
    hostName = "maliwan";
    firewall.enable = false;
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "enp*" "wlan*" "wlp*" ];
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
  };
  hardware.bluetooth.enable = true;
}
