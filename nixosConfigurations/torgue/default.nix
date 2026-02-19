{ pkgs
, ...
}: {
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEbmDddLZ2QyGJZWsTVcev4hlzrQFt19+HOLLV14H5B root@torgue";
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

  services.runtimeModules = {
    enable = true;
    flakeUrl = "path:/home/kari/nix-config";
    builtinModules.enable = true;
    modules = [
      {
        name = "retroarch";
        imports = [ ../.config/retroarch.nix ];
      }
      {
        name = "ai-tools";
        imports = [ ../.config/ai-tools.nix ];
      }
      {
        name = "daw";
        imports = [ /mnt/860/home/kari/other/daw.nix ];
        skipValidation = true;
      }
    ];
  };

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # Connectivity
  networking = {
    hostName = "torgue";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 6742 ];
    };
    useDHCP = false;
    wireless.iwd = {
      enable = true;
      settings = {
        General.StateDirectory = "/etc/iwd";
        Network.EnableIPv6 = true;
        Settings.AutoConnect = false;
      };
    };
  };
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    links."10-wol" = {
      matchConfig.MACAddress = "d4:5d:64:d1:12:52";
      linkConfig = {
        NamePolicy = "kernel database onboard slot path";
        WakeOnLan = "magic";
      };
    };
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "enp3s0" ];
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
      "20-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "wlp7s0" ];
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
  };

  # Monitoring
  services.monitoring = {
    enable = true;
    openFirewall = true;
  };

  # OpenRGB startup profile (openrgb-default.orp):
  #   Device 0 (motherboard): 330066 (dark purple) at full color value (100%)
  #   Device 1 zone 0 (Corsair ch1): 43012B (half of 850255 — 50%)
  #   Device 1 zone 1 (Corsair ch2): 1A0033 (half of 330066 — 50%)
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    server.port = 6742;
    startupProfile = "${./openrgb-default.orp}";
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # Service account for remote management
  users.users.service = {
    isSystemUser = true;
    group = "service";
    shell = "/bin/sh";
    openssh.authorizedKeys.keys = [
      ''command="sudo systemctl poweroff",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICne6AlhwNtQ6/whwnSdPUGQge3lRzebrk+ahd7qqn7W hass@vladof''
    ];
  };
  users.groups.service = { };
  security.sudo.extraRules = [{
    users = [ "service" ];
    commands = [{
      command = "/run/current-system/sw/bin/systemctl poweroff";
      options = [ "NOPASSWD" ];
    }];
  }];
}
