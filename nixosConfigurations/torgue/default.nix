{ pkgs
, inputs
, ...
}: {
  # openrgb 1.0rc2 (26.05) regressed the client `-z`/`--size` CLI parser (any
  # `-z` -> "Invalid option"), so the Corsair zone sizes can't be set and its
  # LEDs stay dark. Pin openrgb to 25.11's 0.9 (server + client) until fixed.
  nixpkgs.overlays = [
    (_: prev: { openrgb = inputs.nixpkgs-2511.legacyPackages.${prev.stdenv.hostPlatform.system}.openrgb; })
  ];

  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEbmDddLZ2QyGJZWsTVcev4hlzrQFt19+HOLLV14H5B root@torgue";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    ../.config/hw/bluetooth.nix
    ../.config/hw/cpu-amd.nix
    ../.config/hw/gpu-amd.nix
    ../.config/hw/gamepad.nix
    ../.config/keyd.nix
    ../.config/hw/pipewire.nix
    ../.config/nix-ld.nix
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
        name = "retroarch";
        imports = [ ../.config/retroarch.nix ];
      }
      {
        name = "ai-tools";
        imports = [ ../.config/ai-tools.nix ];
      }
      {
        name = "ollama";
        imports = [ ../.config/ollama-amd.nix ];
      }
      {
        name = "auto-scrcpy";
        imports = [ ../.config/auto-scrcpy.nix ];
      }
      {
        name = "plexamp";
        imports = [{
          environment.systemPackages = with pkgs; [
            plexamp
          ];
        }];
      }
      {
        name = "daw";
        imports = [ /mnt/860/home/kari/other/daw.nix ];
        postEnable = "bitwig-studio";
        skipValidation = true;
      }
    ];
  };

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # NTFS support
  boot.supportedFilesystems = [ "ntfs" ];
  environment.systemPackages = [ pkgs.ntfs3g ];

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
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV6Config.DUIDType = "link-layer";
      };
      "20-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "wlp7s0" ];
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV6Config.DUIDType = "link-layer";
      };
    };
  };

  # Monitoring + central log shipping
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
      # Devices (esp. the Corsair USB HID) enumerate after the server socket is
      # up, so early runs hit "Invalid device ID"; retry until they appear.
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
