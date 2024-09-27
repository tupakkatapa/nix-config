{ lib
, pkgs
, config
, ...
}: {
  imports = [
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ../.config/yubikey.nix
    ./ephemeral.nix
  ];

  # Nixos-hardware
  hardware.amdgpu = {
    amdvlk.enable = true;
    initrd.enable = true;
  };

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
  systemd.services.openrgb = {
    description = "OpenRGB Daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.openrgb}/bin/openrgb --server";
      Restart = "on-failure";
    };
  };
  services.udev.packages = [ pkgs.openrgb-with-all-plugins ];
  # You must load the i2c-dev module along with the correct i2c driver for your motherboard.
  # This is usually i2c-piix4 for AMD systems and i2c-i801 for Intel systems.
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];

  # System packages
  environment.systemPackages = with pkgs; [
    openrgb-with-all-plugins
    liquidctl
  ];
}
