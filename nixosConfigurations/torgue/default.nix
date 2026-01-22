{ pkgs
, ...
}: {
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEbmDddLZ2QyGJZWsTVcev4hlzrQFt19+HOLLV14H5B root@torgue";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  # environment.systemPackages = with pkgs; [
  #   wayvnc
  # ];

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
        name = "games";
        imports = [ ../.config/games.nix ];
      }
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
        imports = [ ../.config/daw.nix ];
      }
    ];
  };

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # Wireless VR Streaming
  # programs.alvr = {
  #   enable = true;
  #   openFirewall = true;
  # };

  # Required for automounting
  # services.udisks2.enable = true;

  # Connectivity
  networking = {
    hostName = "torgue";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 ]; # magic port
    };
    useDHCP = false;
    wireless = {
      enable = true;
      userControlled.enable = true;
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
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
}
