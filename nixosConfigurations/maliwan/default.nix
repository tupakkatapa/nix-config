{ pkgs, ... }: {
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9ktPcKS8ma2/F2OgmJvQez+tItcIAHEnNmkWhnUQob root@maliwan";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  # Bluetooth pairing keys; re-pairing a device needs a re-export
  age.secrets.bt-galaxy-buds4-pro = {
    rekeyFile = ./secrets/bt-galaxy-buds4-pro.age;
    path = "/var/lib/bluetooth/48:45:E6:14:DB:E2/78:C1:1D:EA:46:EF/info";
    symlink = false;
  };
  age.secrets.bt-corsair-virtuoso-xt = {
    rekeyFile = ./secrets/bt-corsair-virtuoso-xt.age;
    path = "/var/lib/bluetooth/48:45:E6:14:DB:E2/80:7B:1E:02:53:95/info";
    symlink = false;
  };
  age.secrets.bt-mx-master-2s = {
    rekeyFile = ./secrets/bt-mx-master-2s.age;
    path = "/var/lib/bluetooth/48:45:E6:14:DB:E2/CC:47:F4:B7:4B:B1/info";
    symlink = false;
  };

  imports = [
    ../.config/hw/bluetooth.nix
    ../.config/hw/cpu-amd.nix
    ../.config/hw/gpu-amd.nix
    ../.config/keyd.nix
    ../.config/nix-ld.nix
    ../.config/hw/pipewire.nix
    ../.config/podman.nix
    ../.config/tuigreet-hypr.nix
    ../.config/hw/yubikey.nix
    ./persistence.nix
  ];

  services.runtimeModules = {
    enable = true;
    flakeUrl = "path:/home/kari/Workspace/tupakkatapa/nix-config";
    builtinModules.enable = true;
    modules = [
      {
        name = "auto-scrcpy";
        imports = [ ../.config/auto-scrcpy.nix ];
      }
      {
        name = "plexamp";
        imports = [{ environment.systemPackages = [ pkgs.plexamp ]; }];
      }
    ];
  };

  services.tpmHostKey.enable = true;

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # Monitoring + central log shipping
  services.monitoring.enable = true;

  # Battery-aware power management
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_BOOST_ON_BAT = 1;
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      PCIE_ASPM_ON_BAT = "powersave";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };

  # Lid closed on external power means docked; logind's own dock check
  # counts external displays, which vanish when the monitor sleeps
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # Firmware updates (BIOS, EC, dock) via LVFS
  services.fwupd.enable = true;

  # Connectivity
  networking = {
    hostName = "maliwan";
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
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
    links."10-wol" = {
      matchConfig.MACAddress = "18:3d:2d:d2:de:41";
      linkConfig = {
        NamePolicy = "kernel database onboard slot path";
        WakeOnLan = "magic";
      };
    };
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        # Any wired NIC; a dock's name follows the USB-C port it hangs off
        matchConfig.Name = [ "en*" "wlan0" ];
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          # Stays the default DNS route despite its route-only domain
          DNSDefaultRoute = true;
        };
        dhcpV6Config.DUIDType = "link-layer";
        # Resolves outside the tunnel it brings up
        domains = [ "~vpn.coditon.com" ];
      };
    };
  };
}
