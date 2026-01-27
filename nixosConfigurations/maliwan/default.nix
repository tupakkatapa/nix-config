{ pkgs, ... }: {
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcbYE9n5NE8EhxIrlR9tc4ZredoxvTPubQniNGQWH+s root@maliwan";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    ../.config/gaming-amd.nix
    ../.config/keyd.nix
    ../.config/pipewire.nix
    ../.config/podman.nix
    ../.config/tuigreet-hypr.nix
    ../.config/yubikey.nix
    ./persistence.nix
  ];

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Connectivity
  networking = {
    hostName = "maliwan";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 ]; # magic port
    };
    useDHCP = false;
    wireless.iwd = {
      enable = true;
      settings = {
        General.StateDirectory = "/etc/iwd";
        Network.EnableIPv6 = true;
        Settings.AutoConnect = true;
      };
    };
  };
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "enp195s0f0" "wlp194s0" ];
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
}
