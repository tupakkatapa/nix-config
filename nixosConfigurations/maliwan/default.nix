{ pkgs, ... }: {
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcbYE9n5NE8EhxIrlR9tc4ZredoxvTPubQniNGQWH+s root@maliwan";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    ../.config/hw/bluetooth.nix
    ../.config/hw/cpu-amd.nix
    ../.config/hw/gpu-amd.nix
    ../.config/keyd.nix
    ../.config/hw/pipewire.nix
    ../.config/podman.nix
    ../.config/tuigreet-hypr.nix
    ../.config/hw/yubikey.nix
    ./persistence.nix
  ];

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # Monitoring + central log shipping
  services.monitoring.enable = true;

  # Battery-aware power management
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_BOOST_ON_BAT = 1;
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      PCIE_ASPM_ON_BAT = "powersave";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };

  # Firmware updates (BIOS, EC, dock) via LVFS
  services.fwupd.enable = true;

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
        matchConfig.Name = [ "enp195s0f0" "wlan0" ];
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV6Config.DUIDType = "link-layer";
      };
    };
  };
}
