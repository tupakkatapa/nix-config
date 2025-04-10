{ pkgs
, inputs
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
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ../.config/yubikey.nix
    ./persistence.nix
  ];

  services.runtimeModules = {
    enable = true;
    flakeUrl = "path:${inputs.self.outPath}";
    builtinModules.enable = true;
  };

  # High quality games
  environment.systemPackages = with pkgs; [
    # runelite
    osu-lazer
    bottles
  ];
  # programs.anime-game-launcher.enable = true;

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;

  # Enable ADB for android development
  programs.adb.enable = true;

  # Required if swaylock is installed via home-manager
  security.pam.services.swaylock = { };

  # Connectivity
  networking = {
    hostName = "torgue";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ]; # magic port
    };
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = "enp3s0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
        address = [ "192.168.1.7/24" ]; # static IP
      };
    };
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
}
