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
        path = ../.config/games.nix;
      }
      {
        name = "retroarch";
        path = ../.config/retroarch.nix;
      }
      {
        name = "ai-tools";
        path = ../.config/ai-tools.nix;
      }
    ];
  };

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;

  # Wireless VR Streaming
  # programs.alvr = {
  #   enable = true;
  #   openFirewall = true;
  # };

  # Enable ADB for android development
  programs.adb.enable = true;

  # Required if swaylock is installed via home-manager
  security.pam.services.swaylock = { };

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
    wireless.enable = true;
  };
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
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
