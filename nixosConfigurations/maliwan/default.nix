{ pkgs, ... }: {
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcbYE9n5NE8EhxIrlR9tc4ZredoxvTPubQniNGQWH+s root@maliwan";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

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
    wireless.enable = true;
  };
  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "enp2s0" "wlp3s0" ];
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
  };
  hardware.bluetooth.enable = true;
}
