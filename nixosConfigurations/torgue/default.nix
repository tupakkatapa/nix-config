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

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    server.port = 6742;
  };

  # Apply colors after server is ready (client mode)
  systemd.services.openrgb-colors = {
    description = "Apply OpenRGB colors";
    after = [ "openrgb.service" ];
    requires = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      StartLimitIntervalSec = 90;
      StartLimitBurst = 10;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
    };
    path = [ pkgs.openrgb ];
    script = ''
      # Set Corsair zone sizes (resets on power cycle)
      openrgb --client -d 1 -z 0 --mode static --size 30 --color 000000
      openrgb --client -d 1 -z 1 --mode static --size 30 --color 000000
      # Apply colors (Corsair at 50% brightness: 850255->43012B, 330066->1A0033)
      openrgb --client -d 0 --mode static --color 330066
      openrgb --client -d 1 -z 0 --mode direct --color 43012B
      openrgb --client -d 1 -z 1 --mode direct --color 1A0033
    '';
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
