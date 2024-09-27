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
  services.hardware.openrgb.enable = true;
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];
  hardware.i2c.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    i2c-tools
    liquidctl
  ];
}
