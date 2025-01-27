{ lib
, config
, ...
}: {
  imports = [
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ../.config/yubikey.nix
    ./ephemeral.nix
    # ./gaming.nix
    # ./media-production.nix
    # ./music-production.nix
  ];

  # Enable blobs
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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
    firewall.enable = false;
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

  # Optimize kernel for low-latency audio
  powerManagement.cpuFreqGovernor = "performance";
  musnix.enable = true;

  # OpenRGB
  # Device "Corsair Lightning Node" > Zone "0" > Size "0-18"
  # Device "Corsair Lightning Node" > Zone "1" > Size "0-30"
  services.hardware.openrgb.enable = true;
}
